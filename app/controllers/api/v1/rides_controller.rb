class Api::V1::RidesController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_rider!, only: [:create]

  def create
    ride = Ride.create!(
      rider: current_user,
      status: "requested"
    )

    render json: ride, status: :created
  end

  def show
    ride = Ride.find(params[:id])
    render json: ride
  end
end
