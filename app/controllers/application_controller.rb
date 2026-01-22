class ApplicationController < ActionController::API
  before_action :authenticate_request

  attr_reader :current_user

  private

  def authenticate_request
    token = bearer_token
    payload = JwtService.decode(token)

    if payload.nil?
      render_unauthorized("Invalid or expired token") and return
    end

    @current_user = User.find_by(id: payload[:user_id])

    if @current_user.nil?
      render_unauthorized("User not found") and return
    end
  end

  def bearer_token
    header = request.headers['Authorization']
    return nil unless header&.start_with?('Bearer ')

    header.split(' ').last
  end

  def render_unauthorized(message)
    render json: {
      error: "Unauthorized",
      message: message
    }, status: :unauthorized
  end
end
