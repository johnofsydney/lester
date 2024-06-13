class CreateTransfers < ActiveRecord::Migration[7.0]
  def change
    create_table :transfers do |t|
      t.references :giver, polymorphic: true, index: true
      t.references :taker, polymorphic: true, index: true
      t.integer :amount, default: 0
      t.text :evidence
      t.text :transfer_type
      t.date :effective_date

      t.timestamps
    end
  end
end