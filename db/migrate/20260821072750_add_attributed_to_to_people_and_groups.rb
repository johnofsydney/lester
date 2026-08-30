class AddAttributedToToPeopleAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :attributed_to, :string
    add_column :groups, :attributed_to, :string
  end
end
