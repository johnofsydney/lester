class AddLeadershipWebsite < ActiveRecord::Migration[8.0]
  def change
      create_table :leadership_websites do |t|
      t.references :group, index: true
      t.text :url
      t.text :name_selector
      t.text :title_selector


      t.timestamps
    end
  end
end
