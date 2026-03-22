class RenameAecIdToGroupsAecIdLegacy < ActiveRecord::Migration[8.0]
  def change
    rename_column :groups, :aec_id, :aec_id_legacy
    rename_index :groups, 'index_groups_on_aec_id', 'index_groups_on_aec_id_legacy' if index_exists?(:groups, 'index_groups_on_aec_id')
  end
end
