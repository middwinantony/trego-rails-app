class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|

      t.timestamps
    end
  end
end
