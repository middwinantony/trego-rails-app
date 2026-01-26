class Api::V1::Admin::UsersController < ApplicationController
  before_action :authorize_admin!

  def index
    render json: { message: "All users visible" }
  end

  def show
  end
end
