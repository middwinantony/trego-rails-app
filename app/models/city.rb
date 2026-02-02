class City < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :rides, dependent: :nullify
end
