class RenameAecIdToPeopleAecIdLegacy < ActiveRecord::Migration[8.0]
  def change
    rename_column :people, :aec_id, :aec_id_legacy
    rename_index :people, 'index_people_on_aec_id', 'index_people_on_aec_id_legacy' if index_exists?(:people, 'index_people_on_aec_id')
  end
end
