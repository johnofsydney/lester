class DropAffiliationsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :affiliations, if_exists: true
  end
end
