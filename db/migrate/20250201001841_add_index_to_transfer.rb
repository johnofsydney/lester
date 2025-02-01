class AddIndexToTransfer < ActiveRecord::Migration[7.0]
  def change
    add_index :transfers, :effective_date
  end
end
