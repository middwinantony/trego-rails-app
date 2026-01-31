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

    authorize_ride_access!(ride)

    render json: RideSerializer.new(ride, current_user).as_json
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unauthorized
  end

  private

  def prevent_multiple_active_rides!
    active_ride = Ride.where(
      rider_id: current_user.id,
      status: [:requested, :assigned, :accepted, :started]
    ).exists?

    if active_ride
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

  def authorize_ride_access!(ride)
    return if current_user.admin?
    return if current_user.rider? && ride.rider_id == current_user.id
    return if current_user.driver? && ride.driver_id == current_user.id

    raise StandardError, "Unauthorized"
  end
end
