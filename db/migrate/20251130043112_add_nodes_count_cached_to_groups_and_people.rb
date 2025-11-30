class AddNodesCountCachedToGroupsAndPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :nodes_count_cached, :integer
    add_column :groups, :nodes_count_cached_at, :datetime

    add_column :people, :nodes_count_cached, :integer
    add_column :people, :nodes_count_cached_at, :datetime
  end
end
