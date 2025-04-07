class AddLinkedIngestedToPerson < ActiveRecord::Migration[7.0]
  def change
    add_column :people, :linkedin_ingested, :date
  end
end
