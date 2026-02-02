class AddMissingIndexesAndForeignKeys < ActiveRecord::Migration[7.1]
  def change
    # Add indexes for vehicles table
    add_index :vehicles, :driver_id unless index_exists?(:vehicles, :driver_id)
    add_index :vehicles, :plate_number, unique: true unless index_exists?(:vehicles, :plate_number)

    # Add foreign key for vehicles
    add_foreign_key :vehicles, :users, column: :driver_id unless foreign_key_exists?(:vehicles, :users, column: :driver_id)

    # Add city_id columns if they don't exist
    unless column_exists?(:rides, :city_id)
      add_column :rides, :city_id, :bigint
      add_index :rides, :city_id
      add_foreign_key :rides, :cities, column: :city_id
    end

    unless column_exists?(:users, :city_id)
      add_column :users, :city_id, :bigint
      add_index :users, :city_id
      add_foreign_key :users, :cities, column: :city_id
    end
  end
end
