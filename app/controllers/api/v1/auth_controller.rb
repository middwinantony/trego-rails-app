class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [:signup, :login]
  before_action :authenticate_request, only: [:logout]

  def signup
    user = User.new(user_params)
    user.encrypted_password = BCrypt::Password.create(params[:password])
    user.role ||= :rider
    user.status ||= :active

    if user.save
      token = JwtService.encode(
        user_id: user.id,
        role: user.role
      )
      render json: {
        token: token,
        user: user_response(user)
      }, status: :created
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user && BCrypt::Password.new(user.encrypted_password) == params[:password]
      token = JwtService.encode(
        user_id: user.id,
        role: user.role
      )

      render json: {
        token: token,
        user: user_response(user)
      }, status: :ok
    else
      render json: {
        error: "Unauthorized",
        message: "Invalid email or password"
      }, status: :unauthorized
    end
  end

  def logout
    token = bearer_token
    payload = JwtService.decode(token)

    if payload && payload[:jti] && payload[:exp]
      JwtService.blacklist!(payload[:jti], payload[:exp])
      render json: { message: "Logged out successfully" }, status: :ok
    else
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end

  private

  def bearer_token
    header = request.headers['Authorization']
    return nil unless header&.start_with?('Bearer ')

    header.split(' ').last
  end

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end

  def user_response(user)
    {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
