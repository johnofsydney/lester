class AddContractBackfillsTable < ActiveRecord::Migration[7.2]
  def change
    create_table :contract_backfills do |t|
      t.date :last_processed_date, null: false
      t.boolean :day_running, default: false, null: false
      t.datetime :day_started_at
      t.timestamps
    end

    add_index :contract_backfills, :last_processed_date, unique: true
  end
end
