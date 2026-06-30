class RemoveAecIdLegacyFromPerson < ActiveRecord::Migration[8.0]
  def change
    remove_column :people, :aec_id_legacy, :string
  end
end
