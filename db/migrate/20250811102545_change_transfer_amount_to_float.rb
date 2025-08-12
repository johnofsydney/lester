class ChangeTransferAmountToFloat < ActiveRecord::Migration[7.2]
  def change
    change_column :transfers, :amount, :float, null: false, default: 0.0
  end
end
