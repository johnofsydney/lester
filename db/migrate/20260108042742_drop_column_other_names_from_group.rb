class DropColumnOtherNamesFromGroup < ActiveRecord::Migration[7.2]
  def change
    remove_column :groups, :other_names, :text
  end
end
