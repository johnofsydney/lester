class AddBusinessNumberToGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :business_number, :string
  end
end
