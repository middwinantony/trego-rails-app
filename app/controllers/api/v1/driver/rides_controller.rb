class Api::V1::Driver::RidesController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_driver!

  def index
    # driver views available rides
    rides = Ride.where(status: :requested)
    render json: rides
  end

  def accept
    ride = Ride.find(params[:id])

    RideLifecycleService.new(ride, current_user).accept!
    render json: ride, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def start
    ride = Ride.find(params[:id])

    RideLifecycleService.new(ride, current_user).start!
    render json: ride, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def complete
    ride = Ride.find(params[:id])

    RideLifecycleService.new(ride, current_user).complete!
    render json: ride, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
