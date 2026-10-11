class CreateIngestSourceStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :ingest_source_statuses do |t|
      t.string :key, null: false
      t.datetime :last_run_at
      t.datetime :last_success_at
      t.datetime :last_failure_at
      t.string :last_error, limit: 1000

      t.timestamps
    end

    add_index :ingest_source_statuses, :key, unique: true
  end
end
