# NOTE: this class is NOT backed by a table. It does NOT inherit from ActiveRecord
# It is a simple data object that holds data from the node, used for display


class ConsolidatedTransfer
  attr_accessor :transfer, :depth, :direction

  def initialize(transfer:, depth:, direction:)
    @transfer = transfer
    @depth = depth
    @direction = direction
  end

  def id = transfer.id
  def amount = transfer.amount
  def effective_date = transfer.effective_date
  def giver = transfer.giver
  def taker = transfer.taker

  def to_h
    {
      id:,
      amount:,
      effective_date:,
      giver_type: giver.class.to_s,
      giver_id: giver.id,
      giver_name: giver.name,
      taker_type: taker.class.to_s,
      taker_id: taker.id,
      taker_name: taker.name,
      depth:,
      direction:
    }
  end
end