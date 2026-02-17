class AddGiverAndTakerToIndividualTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :individual_transactions, :giver, polymorphic: true
    add_reference :individual_transactions, :taker, polymorphic: true

    add_column :individual_transactions, :transaction_type, :text
  end
end
