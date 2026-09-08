class AddStateElectionDataToPeople < ActiveRecord::Migration[8.0]
  def change
    change_table :people, bulk: true do |t|
      t.jsonb :state_election_data, default: [], null: false
      t.datetime :state_election_data_updated_at
    end
  end
end
