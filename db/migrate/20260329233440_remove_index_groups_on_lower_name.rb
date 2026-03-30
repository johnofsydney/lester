class RemoveIndexGroupsOnLowerName < ActiveRecord::Migration[8.0]
  def change
    remove_index :groups, name: 'index_groups_on_lower_name'
  end
end
