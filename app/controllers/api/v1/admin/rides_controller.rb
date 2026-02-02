class Api::V1::Admin::RidesController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin!

  def index
    rides = Ride.includes(:rider, :driver, :city, :vehicle)
                .order(created_at: :desc)
                .page(params[:page])
                .per(params[:per_page] || 25)

    render json: {
      rides: rides.map { |ride| serialize_ride(ride) },
      pagination: {
        current_page: rides.current_page,
        total_pages: rides.total_pages,
        total_count: rides.total_count,
        per_page: rides.limit_value
      }
    }
  end

  def force_cancel
    ride = Ride.find(params[:id])

    RideLifecycleService.new(ride, current_user).admin_cancel!
    render json: {
      message: "Ride force-cancelled by admin",
      ride: serialize_ride(ride.reload)
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def serialize_ride(ride)
    {
      id: ride.id,
      status: ride.status,
      pickup_location: ride.pickup_location,
      dropoff_location: ride.dropoff_location,
      rider: serialize_user(ride.rider),
      driver: ride.driver ? serialize_user(ride.driver) : nil,
      vehicle: ride.vehicle ? serialize_vehicle(ride.vehicle) : nil,
      city: ride.city ? { id: ride.city.id } : nil,
      assigned_at: ride.assigned_at,
      accepted_at: ride.accepted_at,
      started_at: ride.started_at,
      completed_at: ride.completed_at,
      cancelled_at: ride.cancelled_at,
      created_at: ride.created_at,
      updated_at: ride.updated_at
    }
  end

  def serialize_user(user)
    {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status
    }
  end

  def serialize_vehicle(vehicle)
    {
      id: vehicle.id,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      plate_number: vehicle.plate_number
    }
  end
end
