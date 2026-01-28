# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

User.find_or_create_by!(email: "admin@trego.com") do |u|
  u.password = "password123"
  u.role = "admin"
  u.status = "active"
end

User.find_or_create_by!(email: "driver@trego.com") do |u|
  u.password = "password123"
  u.role = "driver"
  u.status = "active"
end

User.find_or_create_by!(email: "rider@trego.com") do |u|
  u.password = "password123"
  u.role = "rider"
  u.status = "active"
end
