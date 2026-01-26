class Api::V1::Driver::RidesController < ApplicationController
  before_action :authorize_driver!

  def index
    # driver views available rides
    render json: { message: "Available rides"}
  end
end
