class SetDefaultDataOnTransfers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :transfers, :data, from: nil, to: {}
  end
end
