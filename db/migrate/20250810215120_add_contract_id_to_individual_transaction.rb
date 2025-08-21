class AddContractIdToIndividualTransaction < ActiveRecord::Migration[7.2]
  def change
    add_column :individual_transactions, :contract_id, :string
  end
end
