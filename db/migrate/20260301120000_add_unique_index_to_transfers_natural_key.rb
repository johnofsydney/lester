class AddUniqueIndexToTransfersNaturalKey < ActiveRecord::Migration[7.0]
  def change
    add_index :transfers,
              [:giver_type, :giver_id, :taker_type, :taker_id, :effective_date, :transfer_type, :evidence],
              unique: true,
              name: "index_transfers_on_natural_key"
  end
end
