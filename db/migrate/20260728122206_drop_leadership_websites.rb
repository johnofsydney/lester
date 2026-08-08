class DropLeadershipWebsites < ActiveRecord::Migration[8.1]
  def change
    drop_table :leadership_websites do |t|
      t.datetime 'created_at', null: false
      t.bigint 'group_id'
      t.text 'name_selector'
      t.text 'people_card_selector'
      t.date 'reviewed_at'
      t.text 'title_selector'
      t.datetime 'updated_at', null: false
      t.text 'url'
      t.index ['group_id'], name: 'index_leadership_websites_on_group_id'
    end
  end
end
