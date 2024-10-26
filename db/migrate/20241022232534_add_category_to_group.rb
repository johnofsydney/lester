class AddCategoryToGroup < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :category, :boolean, default: false
  end
end
