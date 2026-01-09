class CreateTradingNames < ActiveRecord::Migration[7.2]
  def change
    create_table :trading_names do |t|
      t.references :owner, polymorphic: true, index: true
      t.text :name

      t.timestamps
    end

    add_index :trading_names, :name
  end
end
