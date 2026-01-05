class AddCategoryToIndividualTransactions < ActiveRecord::Migration[7.2]
  def change
    add_column :individual_transactions, :category, :string
  end
end
