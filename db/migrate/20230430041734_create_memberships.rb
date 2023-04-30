class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      t.bigint :person_id
      t.bigint :group_id
      t.date :start
      t.date :end

      t.timestamps
      t.index [:person_id, :group_id]
    end
  end
end
