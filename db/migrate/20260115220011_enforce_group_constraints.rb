class EnforceGroupConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :groups, :name, false

    # Case-insensitive unique index for name
    add_index :groups, 'LOWER(name)', unique: true, name: 'index_groups_on_lower_name'
  end
end
