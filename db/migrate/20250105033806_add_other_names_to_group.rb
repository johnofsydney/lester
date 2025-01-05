class AddOtherNamesToGroup < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :other_names, :text, array: true, default: []
  end
end
