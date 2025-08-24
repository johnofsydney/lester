class AddIndexesToIndividualTransaction < ActiveRecord::Migration[7.2]
  def change
    add_index :individual_transactions, :effective_date
    add_index :individual_transactions, :contract_id
    add_index :individual_transactions, :external_id
  end
end
