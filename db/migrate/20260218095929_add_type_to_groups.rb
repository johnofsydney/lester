class AddTypeToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :type, :string
  end
end
