class Ride < ApplicationRecord
  belongs_to :rider, class_name: "User"
  belongs_to :driver, class_name: "User", optional: true
  belongs_to :vehicle, optional: true

  enum status: {
    requested: 0,
    assigned: 1,
    accepted: 2,
    started: 3,
    completed: 4,
    cancelled: 5
  }
end
