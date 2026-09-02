class AddTrigramIndexToGroupsName < ActiveRecord::Migration[8.0]
  def change
    add_index :groups, :name, using: :gin, opclass: :gin_trgm_ops,
                              name: 'index_groups_on_name_trigram'
  end
end
