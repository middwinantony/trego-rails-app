class ApplicationController < ActionController::API
  before_action :authenticate_request

  attr_reader :current_user

  private

  # -------------------------
  # Authentication
  # -------------------------
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

  # -------------------------
  # Authorization Guards
  # -------------------------
  def authorize_user!
    render_forbidden("Access denied") and return unless current_user
  end

  def authorize_rider!
    unless current_user.rider?
      render json: { errors: "Rider access only" }, status: :forbidden
      return
    end
  end

  def authorize_driver!
    unless current_user.driver?
      render json: { errors: "Driver access only" }, status: :forbidden
      return
    end
  end

  def authorize_admin!
    render_forbidden("Admin access only") and return unless current_user&.role == "admin"
  end

  # -------------------------
  # Error Helpers
  # -------------------------
  def render_unauthorized(message)
    render json: {
      error: "Unauthorized",
      message: message
    }, status: :unauthorized
  end

  def render_forbidden(message)
    render json: {
      error: "Forbidden",
      message: message
    }, status: :forbidden
  end
end
