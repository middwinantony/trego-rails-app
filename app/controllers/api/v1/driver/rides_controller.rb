class Api::V1::Driver::RidesController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_driver!

  def index
    # driver views available rides
    render json: { message: "Available rides"}
  end

  def accept
    ride = Ride.find(params[:id])

    RideLifecycleService.new(ride, current_user).accept!

    render json: ride
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
