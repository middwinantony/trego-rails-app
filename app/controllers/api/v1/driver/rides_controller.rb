class Api::V1::Driver::RidesController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_driver!
  before_action :prevent_accept_spam, only: [:accept]

  def index
    # Driver views available rides (optionally filtered by city)
    rides = Ride.where(status: :requested)

    # Filter by city if provided
    if params[:city_id].present?
      rides = rides.where(city_id: params[:city_id])
    elsif current_user.city_id.present?
      # Default to driver's city
      rides = rides.where(city_id: current_user.city_id)
    end

    rides = rides.order(created_at: :asc).limit(20)

    render json: rides.map { |ride| serialize_ride(ride) }
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

  def cancel
    ride = Ride.find(params[:id])

    RideLifecycleService.new(ride, current_user).driver_cancel!
    render json: {
      message: "Ride cancelled by driver",
      ride: ride.reload
    }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def prevent_accept_spam
    # Check Redis first for active ride (faster)
    active_ride = RedisService.get_active_ride(current_user.id)

    if active_ride
      render json: {
        error: "Active ride exists",
        message: "You already have an active ride"
      }, status: :unprocessable_entity
      return
    end

    # Prevent drivers from accepting too many rides too quickly
    recent_accepts = Ride.where(
      driver_id: current_user.id,
      status: [:assigned, :accepted]
    ).where('assigned_at > ?', 10.seconds.ago).count

    if recent_accepts >= 3
      render json: {
        error: "Too many accepts",
        message: "You're accepting rides too quickly. Please wait a moment."
      }, status: :too_many_requests
      return
    end
  end

  def serialize_ride(ride)
    {
      id: ride.id,
      pickup_location: ride.pickup_location,
      dropoff_location: ride.dropoff_location,
      status: ride.status,
      rider: {
        id: ride.rider.id,
        first_name: ride.rider.first_name
      },
      created_at: ride.created_at
    }
  end
end
