class CreateTransfers < ActiveRecord::Migration[7.0]
  def change
    create_table :transfers do |t|
      t.references :giver, polymorphic: true, null: false
      t.references :taker, polymorphic: true, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :amount, null: false, default: 0
      t.text :transfer_type, null: false

      t.timestamps
    end
  end
end
