class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :validatable,
         password_length: 8..128

  enum role: {
    rider: 0,
    driver: 1,
    admin: 2
  }

  enum status: {
    active: 0,
    suspended: 1
  }

  # Associations
  belongs_to :city, optional: true
  has_many :vehicles, foreign_key: :driver_id, dependent: :destroy
  has_many :rides_as_rider, class_name: 'Ride', foreign_key: :rider_id, dependent: :destroy
  has_many :rides_as_driver, class_name: 'Ride', foreign_key: :driver_id, dependent: :nullify

  validates :role, presence: true
  validates :status, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Custom password complexity validation
  validate :password_complexity, if: -> { password.present? }

  private

  def password_complexity
    return if password.blank?

    unless password.match?(/\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+\z/)
      errors.add :password, 'must include at least one lowercase letter, one uppercase letter, and one digit'
    end
  end
end
