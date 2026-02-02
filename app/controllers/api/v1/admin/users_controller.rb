class Api::V1::Admin::UsersController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin!

  def index
    users = User.includes(:city)
                .order(created_at: :desc)
                .page(params[:page])
                .per(params[:per_page] || 25)

    # Apply optional filters
    users = users.where(role: params[:role]) if params[:role].present?
    users = users.where(status: params[:status]) if params[:status].present?

    render json: {
      users: users.map { |user| serialize_user(user) },
      pagination: {
        current_page: users.current_page,
        total_pages: users.total_pages,
        total_count: users.total_count,
        per_page: users.limit_value
      }
    }
  end

  def show
    user = User.find(params[:id])
    render json: serialize_user(user)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def update
    user = User.find(params[:id])

    # Prevent admins from demoting themselves
    if user.id == current_user.id && params[:role].present? && params[:role] != 'admin'
      render json: { error: "Cannot change your own role" }, status: :forbidden
      return
    end

    if user.update(admin_user_params)
      render json: serialize_user(user)
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  private

  def admin_user_params
    params.permit(:role, :status, :first_name, :last_name, :city_id)
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
