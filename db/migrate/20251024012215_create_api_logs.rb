class CreateApiLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :api_logs do |t|
      t.string :endpoint
      t.text :message
      t.timestamps
    end
  end
end
