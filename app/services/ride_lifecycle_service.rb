class RideLifecycleService
  def initialize(ride, actor)
    @ride = ride
    @actor = actor
  end

  # DRIVER ACTIONS
  def accept!
    ensure_driver!

    @ride.with_lock do
      ensure_state!(:requested)

      @ride.update!(
        driver: @actor,
        status: :assigned
      )
    end

    @ride
  end

  def start!
    ensure_driver!

    @ride.with_lock do
      ensure_state!(:assigned)

      @ride.update!(status: :started)
    end

    @ride
  end

  def complete!
    ensure_driver!

    @ride.with_lock do
      ensure_state!(:started)

      @ride.update!(status: :completed)
    end

    @ride
  end

  # RIDER ACTIONS
  def cancel!
    ensure_rider!

    @ride.with_lock do
      ensure_state_in!(%i[requested assigned])

      @ride.update!(status: :cancelled)
    end

    @ride
  end

  private

  def ensure_driver!
    raise StandardError, "Driver only action" unless @actor.driver?
  end

  def ensure_rider!
    raise StandardError, "Rider only action" unless @actor.rider?
  end

  def ensure_state!(expected)
    raise StandardError, "Invalid state transition" unless @ride.status.to_sym == expected
  end

  def ensure_state_in!(allowed)
    raise StandardError, "Invalid state transition" unless allowed.include?(@ride.status.to_sym)
  end
end
