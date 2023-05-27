class CreateAffiliations < ActiveRecord::Migration[7.0]
  def change
    create_table :affiliations do |t|
      t.references :owning_group, null: false, foreign_key: { to_table: :groups }
      t.references :sub_group, null: false, foreign_key: { to_table: :groups }

      t.date :start_date # TODO: time range for affiliation
      t.date :end_date
      t.text :title

      t.timestamps
    end
  end
end
# class CreateAffiliations < ActiveRecord::Migration[7.0]
#   def change
#     create_table :affiliations do |t|
#       t.references :parent, null: false, foreign_key: { to_table: :groups }
#       t.references :child, null: false, foreign_key: { to_table: :groups }

#       t.date :start_date # TODO: time range for affiliation
#       t.date :end_date
#       t.text :title

#       t.timestamps
#     end
#   end
# end
