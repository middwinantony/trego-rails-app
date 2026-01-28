class AddLifecycleToRides < ActiveRecord::Migration[7.1]
  def change
    # Add references
    add_reference :rides, :rider, null: false, foreign_key: { to_table: :users }, index: false
    add_reference :rides, :driver, foreign_key: { to_table: :users }, index: false

    # Add status enum
    add_column :rides, :status, :integer, null: false, default: 0

    #Lifecycle timestamps
    add_column :rides, :accepted_at, :datetime
    add_column :rides, :completed_at, :datetime
    add_column :rides, :cancelled_at, :datetime

    # Indexes for performance
    add_index :rides, :status
    add_index :rides, :driver_id, if_not_exists: true
    add_index :rides, :rider_id, if_not_exists: true
  end
end
