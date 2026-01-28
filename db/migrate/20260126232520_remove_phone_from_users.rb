class RemovePhoneFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :phone, :string
  end
end
