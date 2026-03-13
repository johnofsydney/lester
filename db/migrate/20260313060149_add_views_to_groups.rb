class AddViewsToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :views, :integer, default: 0, null: false
  end
end
