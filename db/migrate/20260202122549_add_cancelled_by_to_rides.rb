class AddCancelledByToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :cancelled_by, :string
  end
end
