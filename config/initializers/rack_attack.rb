class Rack::Attack
  # Allow requests from localhost in development
  safelist('allow from localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1' if Rails.env.development?
  end

  ### Throttle Login Attempts ###
  # Limit login attempts by IP address
  throttle('auth/login/ip', limit: 5, period: 60.seconds) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      req.ip
    end
  end

  # Limit login attempts by email
  throttle('auth/login/email', limit: 5, period: 60.seconds) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      # Extract email from request body
      req.params['email']&.downcase
    end
  end

  ### Throttle Signup Attempts ###
  throttle('auth/signup/ip', limit: 3, period: 60.seconds) do |req|
    if req.path == '/api/v1/auth/signup' && req.post?
      req.ip
    end
  end

  ### Throttle Ride Creation ###
  # Limit ride creation per user (requires authenticated user)
  throttle('rides/create', limit: 10, period: 60.seconds) do |req|
    if req.path == '/api/v1/rides' && req.post?
      # Extract user_id from JWT token in Authorization header
      token = req.env['HTTP_AUTHORIZATION']&.split(' ')&.last
      if token
        begin
          payload = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
          payload['user_id']
        rescue JWT::DecodeError
          nil
        end
      end
    end
  end

  ### Throttle Driver Accept ###
  throttle('driver/accept', limit: 20, period: 60.seconds) do |req|
    if req.path.match?(/\/api\/v1\/(driver\/)?rides\/\d+\/accept/) && req.post?
      # Extract user_id from JWT token
      token = req.env['HTTP_AUTHORIZATION']&.split(' ')&.last
      if token
        begin
          payload = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
          payload['user_id']
        rescue JWT::DecodeError
          nil
        end
      end
    end
  end

  ### General API Rate Limit ###
  # Limit all API requests per IP
  throttle('api/ip', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  ### Custom Response for Rate Limiting ###
  self.throttled_responder = lambda do |env|
    retry_after = env['rack.attack.match_data'][:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{
        error: 'Rate limit exceeded',
        message: 'Too many requests. Please try again later.',
        retry_after: retry_after
      }.to_json]
    ]
  end

  ### Track Requests ###
  # Track all requests for monitoring
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    if [:throttle, :blocklist, :blocklist].include?(req.env['rack.attack.match_type'])
      Rails.logger.warn "[RACK-ATTACK] #{req.env['rack.attack.match_type']} #{req.ip} #{req.path}"
    end
  end
end

# Enable rack-attack
Rails.application.config.middleware.use Rack::Attack
