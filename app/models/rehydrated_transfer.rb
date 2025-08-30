# NOTE: this class is NOT backed by a table. It does NOT inherit from ActiveRecord
# It is a simple data object that holds data from the node, used for display


class RehydratedTransfer


  def initialize(cached_hash)
    @cached_hash = cached_hash
  end

  def id = @cached_hash['id']
  def amount = @cached_hash['amount']

  def effective_date
    @cached_hash['effective_date'].to_date if @cached_hash['effective_date'].present?
  end

  def giver_type = @cached_hash['giver_type']
  def giver_id = @cached_hash['giver_id']
  def giver_name = @cached_hash['giver_name']
  def taker_type = @cached_hash['taker_type']
  def taker_id = @cached_hash['taker_id']
  def taker_name = @cached_hash['taker_name']
  def depth = @cached_hash['depth']
  def direction = @cached_hash['direction']

  def values
    [id, amount, effective_date, giver_type, giver_id, giver_name, taker_type, taker_id, taker_name, depth, direction]
  end
end