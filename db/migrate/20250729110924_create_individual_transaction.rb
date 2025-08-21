class CreateIndividualTransaction < ActiveRecord::Migration[7.2]
  def change
    create_table :individual_transactions do |t|
      t.references :transfer, index: true, foreign_key: true
      t.float :amount
      t.text :evidence
      t.string :transfer_type
      t.date :effective_date
      t.string :external_id
      t.string :description

      t.timestamps
    end
  end
end
