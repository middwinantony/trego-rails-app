class Api::V1::RidesController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_rider!, only: [:create]
  before_action :set_ride, only: [:show]

  def create
    prevent_multiple_active_rides!

    ride = Ride.new(
      rider: current_user,
      pickup_location: ride_params[:pickup_location],
      dropoff_location: ride_params[:dropoff_location],
      status: :requested
    )
    # ride = Ride.create!(
    #   rider: current_user,
    #   status: "requested"
    # )
    if ride.save
      render json: ride, status: :created
    else
      render json: { errors: ride.errors.full_message }, status: :unprocessable_entity
    end
  end

  def show
    ride = Ride.find(params[:id])
    render json: ride
  end

  private

  def prevent_multiple_active_rides!
    active_ride = Ride.where(
      rider_id: current_user.id,
      status: [:requested, :assigned, :accepted, :started]
    ).exists?

    if active_ride?
      render json: { errors: "You already have an active ride" }, status: :unprocessable_entity
    end
  end

  def set_ride
    @ride = Ride.find(params[:id])

    unless @ride.rider_id == current_user.id
      render json: { errors: "Not authorized" }, status: :forbidden
    end
  end

  def ride_params
    params.require(:ride).permit(:pickup_location, :dropoff_location)
  end
end
