class AddGiverAndTakerToIndividualTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :individual_transactions, :giver, polymorphic: true
    add_reference :individual_transactions, :taker, polymorphic: true

    rename_column :individual_transactions, :transfer_type, :transaction_type
  end
end
