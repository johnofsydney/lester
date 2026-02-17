class ChangeFineGrainedTransactionCategoriesMajorCategoryNullable < ActiveRecord::Migration[8.0]
  def change
    def change
      change_column_null :fine_grained_transaction_categories, :major_transaction_category_id, true
    end
  end
end
