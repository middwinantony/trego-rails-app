class RideLifecycleService
  def initialize(ride, actor)
    @ride = ride
    @actor = actor
  end

  # DRIVER ACTIONS
  def accept!
    ensure_driver!

    # Check if driver already has an active ride (Redis first, DB fallback)
    existing_ride = RedisService.get_active_ride(@actor.id)
    raise StandardError, "You already have an active ride" if existing_ride

    @ride.with_lock do
      ensure_state!(:requested)

      @ride.update!(
        driver: @actor,
        status: :assigned
      )
    end

    # Update Redis cache
    RedisService.cache_active_ride(@actor.id, @ride.id)
    RedisService.remove_available_driver(@ride.city_id, @actor.id) if @ride.city_id

    # Trigger notification job asynchronously
    RideStatusNotificationJob.perform_later(@ride.id, 'assigned')

    @ride
  end

  def start!
    ensure_driver!
    ensure_driver_owns_ride!

    @ride.with_lock do
      ensure_state!(:assigned)
      @ride.update!(status: :started)
    end

    # Trigger notification job asynchronously
    RideStatusNotificationJob.perform_later(@ride.id, 'started')
  end

  def complete!
    ensure_driver!
    ensure_driver_owns_ride!

    @ride.with_lock do
      ensure_state!(:started)
      @ride.update!(status: :completed)
    end

    # Clear Redis cache (driver is now available again)
    RedisService.clear_active_ride(@actor.id)
    RedisService.add_available_driver(@ride.city_id, @actor.id) if @ride.city_id

    # Trigger notification and completion jobs asynchronously
    RideStatusNotificationJob.perform_later(@ride.id, 'completed')
    RideCompletionJob.perform_later(@ride.id)
  end

  # RIDER ACTIONS
  def cancel!
    ensure_rider!
    ensure_rider_owns_ride!

    driver_id = @ride.driver_id # Store before cancellation

    @ride.with_lock do
      ensure_state_in!(%i[requested assigned])

      @ride.update!(
        status: :cancelled,
        cancelled_by: 'rider'
      )
    end

    # Clear Redis cache if driver was assigned
    if driver_id
      RedisService.clear_active_ride(driver_id)
      RedisService.add_available_driver(@ride.city_id, driver_id) if @ride.city_id
    end

    # Trigger notification job asynchronously
    RideStatusNotificationJob.perform_later(@ride.id, 'cancelled')

    @ride
  end

  # DRIVER CANCELLATION
  def driver_cancel!
    ensure_driver!
    ensure_driver_owns_ride!

    @ride.with_lock do
      ensure_state_in!(%i[assigned accepted started])

      @ride.update!(
        status: :cancelled,
        cancelled_by: 'driver'
      )
    end

    # Clear Redis cache (driver is available again)
    RedisService.clear_active_ride(@actor.id)
    RedisService.add_available_driver(@ride.city_id, @actor.id) if @ride.city_id

    # Trigger notification job asynchronously
    RideStatusNotificationJob.perform_later(@ride.id, 'cancelled')

    @ride
  end

  # ADMIN ACTIONS
  def admin_cancel!
    ensure_admin!

    driver_id = @ride.driver_id # Store before cancellation

    @ride.with_lock do
      # Admin can cancel at any state except already completed/cancelled
      ensure_state_in!(%i[requested assigned accepted started])

      @ride.update!(
        status: :cancelled,
        cancelled_by: 'admin'
      )
    end

    # Clear Redis cache if driver was assigned
    if driver_id
      RedisService.clear_active_ride(driver_id)
      RedisService.add_available_driver(@ride.city_id, driver_id) if @ride.city_id
    end

    # Trigger notification job asynchronously
    RideStatusNotificationJob.perform_later(@ride.id, 'cancelled')

    @ride
  end

  private

  def ensure_driver!
    raise StandardError, "Driver only action" unless @actor.driver?
  end

  def ensure_rider!
    raise StandardError, "Rider only action" unless @actor.rider?
  end

  def ensure_admin!
    raise StandardError, "Admin only action" unless @actor.admin?
  end

  def ensure_rider_owns_ride!
    raise StandardError, "Not your ride" unless @ride.rider_id == @actor.id
  end

  def ensure_state!(expected)
    raise StandardError, "Invalid state transition" unless @ride.status.to_sym == expected
  end

  def ensure_state_in!(allowed)
    raise StandardError, "Invalid state transition" unless allowed.include?(@ride.status.to_sym)
  end

  def ensure_driver_owns_ride!
    raise StandardError, "Not your ride" unless @ride.driver_id == @actor.id
  end
end
