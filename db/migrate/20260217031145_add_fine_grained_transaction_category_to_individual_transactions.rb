class AddFineGrainedTransactionCategoryToIndividualTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :individual_transactions, :fine_grained_transaction_category, foreign_key: true
  end
end
