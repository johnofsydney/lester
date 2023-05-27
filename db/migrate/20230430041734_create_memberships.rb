class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      t.references :member, polymorphic: true, null: false
      t.references :owner, null: false, foreign_key: { to_table: :groups }
      t.date :start_date # TODO: time range for membership
      t.date :end_date
      t.text :title

      t.timestamps
    end
  end
end