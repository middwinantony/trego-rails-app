class Api::V1::Rider::RidesController < ApplicationController
  before_action :authorize_rider!

  def create
    # rider creates a ride
    render json: { message: "Ride requested"}
  end

  def show
  end
end
