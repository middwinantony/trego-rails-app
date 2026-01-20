class User < ApplicationRecord
  has_secure_password

  enum role: {
    rider: 0,
    driver: 1,
    admin: 2
  }

  enum status: {
    active: 0,
    suspended: 1
  }

  validates :phone, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :role, presence: true
  validates :status, presence: true
end
