class RideSerializer
  def initialize(ride, current_user)
    @ride = ride
    @current_user = current_user
  end

  def as_json
    base_data.merge(role_specific_data)
  end

  private

  def base_data
    {
      id: @ride.id,
      status: @ride.status,
      created_at: @ride.created_at
    }
  end

  def role_specific_data
    if @current_user.rider?
      rider_view
    elsif @current_user.driver?
      driver_view
    else
      {}
    end
  end

  def rider_view
    {
      driver: @ride.driver && {
        id: @ride.driver.id,
        first_name: @ride.driver.first_name
      }
    }
  end

  def driver_view
    {
      rider: {
        id: @ride.rider.id,
        first_name: @ride.rider.first_name
      }
    }
  end
end
