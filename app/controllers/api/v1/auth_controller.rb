class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [:signup, :login]

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

  private

  def user_params
    params.permit(:email, :role)
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
