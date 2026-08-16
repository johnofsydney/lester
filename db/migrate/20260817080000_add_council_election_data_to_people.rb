class AddCouncilElectionDataToPeople < ActiveRecord::Migration[8.0]
  def change
    change_table :people, bulk: true do |t|
      t.jsonb :council_election_data, default: [], null: false
      t.datetime :council_election_data_updated_at
    end
  end
end
