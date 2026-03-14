class AddViewsToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :views, :integer, default: 0, null: false
  end
end
