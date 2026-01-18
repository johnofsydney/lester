class EnforceTradingNameConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :trading_names, :name, false
    change_column_null :trading_names, :owner_type, false
    change_column_null :trading_names, :owner_id, false

    add_index :trading_names, [:owner_type, :owner_id, :name], unique: true, name: 'index_trading_names_on_owner_and_name'
  end
end
