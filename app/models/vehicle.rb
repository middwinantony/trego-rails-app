class Vehicle < ApplicationRecord
  belongs_to :driver, class_name: 'User', foreign_key: :driver_id
  has_many :rides, dependent: :nullify

  validates :make, presence: true
  validates :model, presence: true
  validates :year, presence: true, numericality: { only_integer: true, greater_than: 1900, less_than_or_equal_to: -> { Time.current.year + 1 } }
  validates :plate_number, presence: true, uniqueness: true
  validates :driver_id, presence: true
end
