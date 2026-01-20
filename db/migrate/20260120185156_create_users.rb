class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.integer :role
      t.string :phone
      t.integer :status
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end
end
