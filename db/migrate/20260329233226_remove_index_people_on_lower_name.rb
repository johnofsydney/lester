class RemoveIndexPeopleOnLowerName < ActiveRecord::Migration[8.0]
  def change
    remove_index :people, name: 'index_people_on_lower_name'
  end
end
