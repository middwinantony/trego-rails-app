class AddCityReferences < ActiveRecord::Migration[7.1]
  def change
    add_reference :rides, :city, foreign_key: true, type: :bigint
    add_reference :users, :city, foreign_key: true, type: :bigint
  end
end
