class AddOpenAustraliaDataToPeople < ActiveRecord::Migration[8.0]
  def change
    change_table :people, bulk: true do |t|
      t.jsonb :open_australia_data, default: [], null: false
      t.datetime :open_australia_data_fetched_at
    end
  end
end
