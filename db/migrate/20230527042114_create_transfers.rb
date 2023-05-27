class CreateTransfers < ActiveRecord::Migration[7.0]
  def change
    create_table :transfers do |t|
      t.references :giver, polymorphic: true, index: true
      t.references :taker, null: false, foreign_key: { to_table: :groups }
      t.integer :amount
      t.text :evidence
      t.text :transfer_type
      t.date :effective_date

      t.timestamps
    end
  end
end