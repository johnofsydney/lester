class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      # TOOD: make it so a group can own another
      # t.references :group, polymorphic: true, null: false
      t.bigint :person_id
      t.bigint :group_id
      t.date :start_date # TODO: time range for membership
      t.date :end_date
      t.text :title

      t.timestamps
      t.index [:person_id, :group_id]
    end
  end
end
