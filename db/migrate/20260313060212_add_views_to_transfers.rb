class AddViewsToTransfers < ActiveRecord::Migration[8.0]
  def change
    add_column :transfers, :views, :integer, default: 0, null: false
  end
end
