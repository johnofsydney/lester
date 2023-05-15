class CreateDonations < ActiveRecord::Migration[7.0]
  def change
    create_table :donations do |t|
      t.references :donor, polymorphic: true, null: false
      t.references :donee, polymorphic: true, null: false
      t.date :date, null: false
      t.integer :amount, null: false

      t.timestamps
    end
  end
end
