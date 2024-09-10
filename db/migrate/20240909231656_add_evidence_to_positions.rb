class AddEvidenceToPositions < ActiveRecord::Migration[7.0]
  def change
    add_column :positions, :evidence, :string
  end
end
