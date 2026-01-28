class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :validatable

  enum role: {
    rider: 0,
    driver: 1,
    admin: 2
  }

  enum status: {
    active: 0,
    suspended: 1
  }

  validates :role, presence: true
  validates :status, presence: true
end
