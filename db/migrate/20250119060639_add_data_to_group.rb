class AddDataToGroup < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :cached_data, :json, default: {}
    Group.reset_column_information
    Group.update_all(cached_data: {})
  end
end
