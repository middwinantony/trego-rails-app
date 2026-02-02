class RideCompletionJob < ApplicationJob
  queue_as :default

  def perform(ride_id)
    ride = Ride.find(ride_id)

    Rails.logger.info "[COMPLETION] Processing ride ##{ride_id}"

    # Calculate fare
    fare = calculate_fare(ride)
    Rails.logger.info "[COMPLETION] Calculated fare: $#{fare}"

    # Create payment record (when Payment model is implemented)
    # payment = Payment.create!(
    #   ride: ride,
    #   amount: fare,
    #   status: :pending,
    #   currency: 'USD'
    # )

    # Update driver statistics
    update_driver_stats(ride.driver, fare) if ride.driver

    # Update rider statistics
    update_rider_stats(ride.rider)

    # Send receipt (future implementation)
    # ReceiptMailer.ride_receipt(ride.id).deliver_later

    Rails.logger.info "[COMPLETION] Ride ##{ride_id} processing complete"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "[COMPLETION] Ride ##{ride_id} not found"
  rescue => e
    Rails.logger.error "[COMPLETION] Error processing ride ##{ride_id}: #{e.message}"
    # Re-raise to trigger Sidekiq retry
    raise
  end

  private

  def calculate_fare(ride)
    # TODO: Implement actual fare calculation
    # This is a placeholder - in production, you'd use:
    # - Distance calculation (using pickup/dropoff coordinates)
    # - Time-based pricing
    # - Surge pricing
    # - Base fare + per-mile rate + per-minute rate

    base_fare = 3.50
    estimated_distance = 5.0 # miles (would come from geocoding)
    per_mile_rate = 2.00
    estimated_time = 15.0 # minutes
    per_minute_rate = 0.35

    fare = base_fare + (estimated_distance * per_mile_rate) + (estimated_time * per_minute_rate)
    fare.round(2)
  end

  def update_driver_stats(driver, fare)
    # TODO: Implement driver statistics tracking
    # This could include:
    # - Total rides completed
    # - Total earnings
    # - Average rating
    # - Acceptance rate
    # - Completion rate

    Rails.logger.info "[STATS] Driver #{driver.id} earned $#{fare} from ride"

    # Example (when statistics model exists):
    # driver_stats = DriverStatistic.find_or_create_by(driver: driver)
    # driver_stats.increment!(:total_rides)
    # driver_stats.increment!(:total_earnings, fare)
  end

  def update_rider_stats(rider)
    # TODO: Implement rider statistics tracking
    # This could include:
    # - Total rides taken
    # - Total spent
    # - Average rating given

    Rails.logger.info "[STATS] Rider #{rider.id} completed a ride"

    # Example (when statistics model exists):
    # rider_stats = RiderStatistic.find_or_create_by(rider: rider)
    # rider_stats.increment!(:total_rides)
  end
end
