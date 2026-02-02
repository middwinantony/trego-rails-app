class Ride < ApplicationRecord
  enum status: {
    requested: 0,
    assigned: 1,
    accepted: 2,
    started: 3,
    completed: 4,
    cancelled: 5
  }

  belongs_to :rider, class_name: "User"
  belongs_to :driver, class_name: "User", optional: true
  belongs_to :city, optional: true
  belongs_to :vehicle, optional: true
  VALID_TRANSITIONS = {
    requested: %i[assigned cancelled],
    assigned: %i[accepted cancelled],
    accepted: %i[started cancelled],
    started: %i[completed cancelled],
    completed: [],
    cancelled: []
  }.freeze

  validates :driver_id, presence: true, if: :driver_required?
  validate :status_transition_is_valid, if: :will_save_change_to_status?

  before_update :set_lifecycle_timestamps

  def can_assign?
    requested?
  end

  def can_accept?
    assigned?
  end

  def can_start?
    accepted?
  end

  def can_complete?
    started?
  end

  def can_cancel?
    requested? || assigned? || accepted? || started?
  end

  private

  def driver_required?
    assigned? || accepted? || started? || completed?
  end

  def status_transition_is_valid
    from = status_before_last_save&.to_sym || :requested
    to = status.to_sym

    return if from == to

    unless VALID_TRANSITIONS[from].include?(to)
      errors.add(:status, "cannot transition from #{from} to #{to}")
    end
  end

  def set_lifecycle_timestamps
    return unless will_save_change_to_status?

    case status.to_sym
    when :assigned
      self.assigned_at ||= Time.current
    when :accepted
      self.accepted_at ||= Time.current
    when :started
      self.started_at ||= Time.current
    when :completed
      self.completed_at ||= Time.current
    when :cancelled
      self.cancelled_at ||= Time.current
    end
  end
end
