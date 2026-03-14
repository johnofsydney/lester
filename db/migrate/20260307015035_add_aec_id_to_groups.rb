class AddAecIdToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :aec_id, :string
    add_index :groups, :aec_id, unique: true
  end
end
