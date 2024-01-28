class AddDataToTransfers < ActiveRecord::Migration[7.0]
  def change
    add_column :transfers, :data, :json
  end
end
