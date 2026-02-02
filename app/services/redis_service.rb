class RedisService
  class << self
    # Get Redis connection
    def redis
      @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'))
    rescue Redis::CannotConnectError => e
      Rails.logger.error "[REDIS] Cannot connect to Redis: #{e.message}"
      nil
    end

    # -------------------------
    # Active Rides Cache
    # -------------------------

    # Cache a driver's active ride
    def cache_active_ride(driver_id, ride_id)
      return unless redis

      redis.setex("driver:#{driver_id}:active_ride", 1.hour.to_i, ride_id)
      true
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to cache active ride: #{e.message}"
      false
    end

    # Get driver's active ride (returns Ride object or nil)
    def get_active_ride(driver_id)
      return nil unless redis

      ride_id = redis.get("driver:#{driver_id}:active_ride")
      ride_id ? Ride.find_by(id: ride_id) : nil
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to get active ride, falling back to DB: #{e.message}"
      # Fallback to database
      Ride.where(driver_id: driver_id, status: [:assigned, :accepted, :started]).first
    rescue ActiveRecord::RecordNotFound
      nil
    end

    # Clear driver's active ride cache
    def clear_active_ride(driver_id)
      return unless redis

      redis.del("driver:#{driver_id}:active_ride")
      true
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to clear active ride: #{e.message}"
      false
    end

    # -------------------------
    # Driver Availability Cache
    # -------------------------

    # Mark driver as available in a city
    def add_available_driver(city_id, driver_id)
      return unless redis && city_id

      redis.sadd("city:#{city_id}:available_drivers", driver_id)
      true
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to add available driver: #{e.message}"
      false
    end

    # Remove driver from available drivers in a city
    def remove_available_driver(city_id, driver_id)
      return unless redis && city_id

      redis.srem("city:#{city_id}:available_drivers", driver_id)
      true
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to remove available driver: #{e.message}"
      false
    end

    # Get all available drivers in a city
    def available_drivers(city_id)
      return [] unless redis && city_id

      driver_ids = redis.smembers("city:#{city_id}:available_drivers")
      User.where(id: driver_ids, role: :driver, status: :active)
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to get available drivers, falling back to DB: #{e.message}"
      # Fallback to database (this will be slower)
      User.where(role: :driver, status: :active, city_id: city_id)
    end

    # -------------------------
    # Ride Cache
    # -------------------------

    # Cache ride data for fast lookups
    def cache_ride(ride)
      return unless redis

      redis.setex(
        "ride:#{ride.id}",
        30.minutes.to_i,
        ride.to_json(
          include: {
            rider: { only: [:id, :email, :first_name, :last_name] },
            driver: { only: [:id, :email, :first_name, :last_name] },
            vehicle: { only: [:id, :make, :model, :year, :plate_number] }
          }
        )
      )
      true
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to cache ride: #{e.message}"
      false
    end

    # Get cached ride data
    def get_cached_ride(ride_id)
      return nil unless redis

      cached = redis.get("ride:#{ride_id}")
      cached ? JSON.parse(cached) : nil
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to get cached ride: #{e.message}"
      nil
    rescue JSON::ParserError => e
      Rails.logger.error "[REDIS] Invalid JSON in cached ride: #{e.message}"
      nil
    end

    # Clear cached ride
    def clear_cached_ride(ride_id)
      return unless redis

      redis.del("ride:#{ride_id}")
      true
    rescue Redis::BaseError => e
      Rails.logger.warn "[REDIS] Failed to clear cached ride: #{e.message}"
      false
    end

    # -------------------------
    # Health Check
    # -------------------------

    # Check if Redis is available
    def healthy?
      return false unless redis

      redis.ping == 'PONG'
    rescue Redis::BaseError
      false
    end

    # Get Redis info
    def info
      return {} unless redis

      {
        connected: healthy?,
        url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
        keys: redis.dbsize
      }
    rescue Redis::BaseError => e
      {
        connected: false,
        error: e.message
      }
    end
  end
end
