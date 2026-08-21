class DropSuggestions < ActiveRecord::Migration[8.1]
  def change
    drop_table :suggestions do |t|
      t.string 'headline', null: false
      t.text 'description'
      t.string 'evidence', null: false
      t.string 'suggested_by'
      t.string 'status'

      t.timestamps
    end
  end
end
