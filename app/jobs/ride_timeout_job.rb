class RideTimeoutJob < ApplicationJob
  queue_as :default

  def perform
    # Find rides that have been in 'requested' state for more than 10 minutes
    timeout_threshold = 10.minutes.ago

    Ride.where(status: :requested)
        .where('created_at < ?', timeout_threshold)
        .find_each do |ride|
      # Cancel the ride due to timeout
      ride.update!(
        status: :cancelled,
        cancelled_by: 'timeout',
        cancelled_at: Time.current
      )

      Rails.logger.info "[TIMEOUT] Ride ##{ride.id} timed out (no driver accepted)"
    end
  end
end
