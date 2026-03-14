class AddReturnIdRegistrationOcdeToIndividualTransaction < ActiveRecord::Migration[8.0]
  def change
    add_column :individual_transactions, :return_id, :integer
    add_column :individual_transactions, :registration_code, :string
  end
end
