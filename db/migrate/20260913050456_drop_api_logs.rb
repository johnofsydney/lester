class DropApiLogs < ActiveRecord::Migration[8.1]
  def up
    drop_table :api_logs
  end

  def down
    create_table :api_logs do |t|
      t.string :endpoint
      t.text :message

      t.timestamps
    end
  end
end
