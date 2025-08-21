class AddExternalIdToTransfers < ActiveRecord::Migration[7.2]
  def change
    add_column :transfers, :external_id, :text
    add_index :transfers, :external_id
  end
end
