class UpdateUsersForPhoneAuth < ActiveRecord::Migration[7.1]
  def change
    # Ensure phone is required and unique
    change_column_null :users, :phone, false
    add_index :users, :phone, unique: true unless index_exists?(:users, :phone)

    # Remove uniqueness on email if it exists
    if index_exists?(:users, :email)
      remove_index :users, :email
    end

    # Ensure password_digest is required
    change_column_null :users, :password_digest, false
  end
end
