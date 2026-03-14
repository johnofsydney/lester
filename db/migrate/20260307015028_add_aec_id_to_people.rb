class AddAecIdToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :aec_id, :string
    add_index :people, :aec_id, unique: true
  end
end
