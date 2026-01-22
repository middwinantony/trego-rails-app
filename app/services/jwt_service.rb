class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base

  EXPIRATION_TIME = 24.hours.from_now.to_i

  def self.encode(payload)
    raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)

    payload = payload.deep_symbolize_keys

    payload[:exp] = EXPIRATION_TIME

    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256')
    decoded[0].with_indifferent_access
  rescue JWT::ExpiredSignature
    nil
  rescue JWT::DecodeError
    nil
  end
end
