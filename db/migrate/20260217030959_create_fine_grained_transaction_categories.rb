class CreateFineGrainedTransactionCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :fine_grained_transaction_categories do |t|
      t.string :name
      t.references :major_transaction_category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
