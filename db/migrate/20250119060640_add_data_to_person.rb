class AddDataToPerson < ActiveRecord::Migration[7.0]
  def change
    add_column :people, :cached_data, :json, default: {}
    Person.reset_column_information
    Person.update_all(cached_data: {})
  end
end