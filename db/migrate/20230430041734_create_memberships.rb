class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      t.references :person, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true

      t.date :start_date # TODO: time range for membership
      t.date :end_date


      t.timestamps
    end
  end
end