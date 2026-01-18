class DropColumnOtherNamesFromPeople < ActiveRecord::Migration[8.0]
  def change
    remove_column :people, :other_names, :text
  end
end
