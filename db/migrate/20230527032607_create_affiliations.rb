class CreateAffiliations < ActiveRecord::Migration[7.0]
  def change
    create_table :affiliations do |t|
      t.references :owning_group, null: false, foreign_key: { to_table: :groups }
      t.references :sub_group, null: false, foreign_key: { to_table: :groups }

      t.date :start_date # TODO: time range for affiliation
      t.date :end_date
      t.text :description

      t.timestamps
    end
  end
end

# Affiliation joining Table vs. Group simpler self join
# PROS
# - more explicit
# - more flexible
# - more extensible
# - can have title, start_date, end_date etc to describe the affiliation
# - preserve the possibility of having a group belong to more than one group
# - should the owning_group really be considered a container rather than an owner? or really peer A and peer B?
# CONS
# - more complex
# - more verbose
# - can a group really have more than one owning group?
#   - if no (probable) then we must use validation to ensure that a sub_group does not belong to many owning groups
#     if no, then eg the federal government cannot have labor for a period, and then the coalition for another period
#     if no, then eg the allegra_spender_campaign would not belong to the teal_independents, because this is not a formal ownership relationship