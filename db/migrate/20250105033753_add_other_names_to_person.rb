class AddOtherNamesToPerson < ActiveRecord::Migration[7.0]
  def change
    add_column :people, :other_names, :text, array: true, default: []
  end
end
