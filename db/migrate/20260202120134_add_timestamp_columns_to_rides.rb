class AddTimestampColumnsToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :assigned_at, :datetime
    add_column :rides, :started_at, :datetime
  end
end
