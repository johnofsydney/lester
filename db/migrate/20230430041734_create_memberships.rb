class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      t.references :member, polymorphic: true, index: true
      t.references :group, null: false, foreign_key: true

      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end