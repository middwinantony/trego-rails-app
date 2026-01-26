class RideLifecycleService
  def initialize(ride, actor)
    @ride = ride
    @actor = actor
  end

  def accept!
    ensure_driver!
    ensure_state!("assigned")

    @ride.update!(status: "accepted")
  end

  def start!
    ensure_driver!
    ensure_state!("accepted")

    @ride.update!(status: "started")
  end

  def completed!
    ensure_driver!
    ensure_state!("started")

    @ride.update!(status: "completed")
  end

  def cancel!
    ensure_rider!
    ensure_state_in!(%w[requested assigned])

    @ride.update!(status: "cancelled")
  end

  private

  def ensure_driver!
    raise StandardError, "Driver only action" unless @actor.role == "driver"
  end

  def ensure_rider!
    raise StandardError, "Rider only action" unless @actor.role == "rider"
  end

  def ensure_state!(expected)
    raise StandardError, "Invalid state transition" unless @ride.status == expected
  end

  def ensure_state_in!(allowed)
    raise StandardError, "Invalid state transition" unless allowed.include?(@ride.status)
  end
end
