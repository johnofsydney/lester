class EnforcePersonConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :people, :name, false

    # Add a case-insensitive unique index for name
    add_index :people, 'LOWER(name)', unique: true, name: 'index_people_on_lower_name'
  end
end
