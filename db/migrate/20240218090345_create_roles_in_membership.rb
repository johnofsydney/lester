class CreateRolesInMembership < ActiveRecord::Migration[7.0]
  def change
    create_table :positions do |t|
      t.references :membership, null: false, foreign_key: true

      t.date :start_date # TODO: time range for position
      t.date :end_date
      t.string :title

      t.timestamps
    end
  end
end
