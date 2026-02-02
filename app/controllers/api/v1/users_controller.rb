class Api::V1::UsersController < ApplicationController
  before_action :authenticate_request

  def show
    user = User.find(params[:id])
    authorize_user_access!(user)

    render json: serialize_user(user)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  private

  def authorize_user_access!(user)
    unless current_user.admin? || current_user.id == user.id
      render json: { errors: "Not authorized to view this user" }, status: :forbidden
      return
    end
  end

  def serialize_user(user)
    {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
      first_name: user.first_name,
      last_name: user.last_name,
      city_id: user.city_id,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
