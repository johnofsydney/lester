class AddSourceToTradingNames < ActiveRecord::Migration[8.1]
  def change
    add_column :trading_names, :source, :string, null: false, default: 'ingest'
  end
end
