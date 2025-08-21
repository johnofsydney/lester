class ChangeTransferAmountToFloat < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/ReversibleMigration
    change_column :transfers, :amount, :float, null: false, default: 0.0
    # rubocop:enable Rails/ReversibleMigration
  end
end
