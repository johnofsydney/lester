class AddAmmendmentIdToIndividualTransactions < ActiveRecord::Migration[7.2]
  def change
    add_column :individual_transactions, :amendment_id, :string
  end
end
