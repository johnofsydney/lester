class DropContractBackfills < ActiveRecord::Migration[8.1]
  def up
    drop_table :contract_backfills
  end

  def down
    create_table :contract_backfills do |t|
      t.date :last_processed_date, null: false

      t.timestamps
    end
    add_index :contract_backfills, :last_processed_date, unique: true
  end
end
