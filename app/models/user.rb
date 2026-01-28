class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  before_create :set_jti

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

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

  private

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
