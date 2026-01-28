class RemoveJtiFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :jti, :string
  end
end
