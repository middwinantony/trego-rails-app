class AddLocationColumnsToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :pickup_location, :string
    add_column :rides, :dropoff_location, :string
  end
end
