class RideStatusNotificationJob < ApplicationJob
  queue_as :default

  def perform(ride_id, event)
    ride = Ride.find(ride_id)

    case event
    when 'assigned'
      notify_rider(ride, "Driver #{ride.driver.first_name || 'N/A'} is on the way!")
      notify_driver(ride, "You accepted ride ##{ride.id}")
    when 'started'
      notify_rider(ride, "Your ride has started")
      notify_driver(ride, "Ride started - heading to destination")
    when 'completed'
      notify_rider(ride, "Ride completed. Thanks for using Trego!")
      notify_driver(ride, "Ride completed successfully")
    when 'cancelled'
      canceller = ride.cancelled_by&.capitalize || 'System'
      notify_rider(ride, "Your ride was cancelled by #{canceller}")
      notify_driver(ride, "Ride was cancelled by #{canceller}") if ride.driver
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "[NOTIFICATION] Ride ##{ride_id} not found"
  rescue => e
    Rails.logger.error "[NOTIFICATION] Error sending notifications for ride ##{ride_id}: #{e.message}"
    # Don't re-raise - we don't want notification failures to break the system
  end

  private

  def notify_rider(ride, message)
    # TODO: Implement actual notification system (SMS, Push, Email)
    # For now, just log
    Rails.logger.info "[NOTIFICATION] Rider #{ride.rider.email}: #{message}"

    # Example: Send SMS via Twilio
    # TwilioService.send_sms(ride.rider.phone, message)

    # Example: Send push notification
    # PushNotificationService.send(ride.rider.id, title: "Ride Update", body: message)
  end

  def notify_driver(ride, message)
    # TODO: Implement actual notification system (SMS, Push, Email)
    # For now, just log
    Rails.logger.info "[NOTIFICATION] Driver #{ride.driver.email}: #{message}"

    # Example: Send SMS via Twilio
    # TwilioService.send_sms(ride.driver.phone, message)

    # Example: Send push notification
    # PushNotificationService.send(ride.driver.id, title: "Ride Update", body: message)
  end
end
