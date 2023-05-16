class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.references :giver, polymorphic: true, null: false
      t.references :taker, polymorphic: true, null: false
      t.date :date, null: false
      t.integer :amount, null: false

      t.timestamps
    end
  end
end
