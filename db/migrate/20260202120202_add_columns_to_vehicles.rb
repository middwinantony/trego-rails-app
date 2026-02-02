class AddColumnsToVehicles < ActiveRecord::Migration[7.1]
  def change
    add_column :vehicles, :make, :string
    add_column :vehicles, :model, :string
    add_column :vehicles, :year, :integer
    add_column :vehicles, :plate_number, :string
    add_column :vehicles, :driver_id, :bigint
    add_column :vehicles, :active, :boolean, default: true

    add_foreign_key :vehicles, :users, column: :driver_id
    add_index :vehicles, :driver_id
    add_index :vehicles, :plate_number, unique: true
  end
end
