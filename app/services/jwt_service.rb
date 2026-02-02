class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base

  # Shorter expiration time for better security (1 hour instead of 24)
  EXPIRATION_TIME = 1.hour

  def self.encode(payload, exp = EXPIRATION_TIME.from_now)
    raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)

    payload = payload.deep_symbolize_keys

    # Add unique token ID for blacklisting
    payload[:jti] = SecureRandom.uuid
    payload[:exp] = exp.to_i

    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256')
    payload = decoded[0].with_indifferent_access

    # Check if token is blacklisted
    return nil if blacklisted?(payload[:jti])

    payload
  rescue JWT::ExpiredSignature
    nil
  rescue JWT::DecodeError
    nil
  end

  # Blacklist a token by its jti
  def self.blacklist!(jti, exp)
    return unless jti

    # Calculate TTL (time until token expires)
    ttl = exp - Time.current.to_i
    return if ttl <= 0 # Token already expired

    # Store in Rails cache (or Redis in production)
    Rails.cache.write("blacklist:#{jti}", true, expires_in: ttl.seconds)
  end

  # Check if a token is blacklisted
  def self.blacklisted?(jti)
    return false unless jti

    Rails.cache.read("blacklist:#{jti}").present?
  end
end
