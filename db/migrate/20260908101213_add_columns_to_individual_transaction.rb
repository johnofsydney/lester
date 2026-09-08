class AddColumnsToIndividualTransaction < ActiveRecord::Migration[8.1]
  def change
    add_column :individual_transactions, :city, :string
    add_column :individual_transactions, :state, :string
    add_column :individual_transactions, :postcode, :string
  end
end
