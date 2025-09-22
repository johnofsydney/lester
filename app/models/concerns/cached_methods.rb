module CachedMethods
  extend ActiveSupport::Concern

  def cached
    RehydratedNode.new(self)
  end

  def cache_fresh?
    return false unless cached_summary_timestamp

    cached_summary_timestamp > 1.week.ago
  end
end

class RehydratedNode
  # It should be OK to have methods in here with same names the group or person (or it's mixins) - the namespace should protect us from ambiguity.
  def initialize(node)
    @node = node
  end

  def klass = node.class.name

  delegate :name, to: :node

  def consolidated_descendents
    # This is a lot of descendents. TODO: use it for downstream methods
    # TODO: decide which to coerce?
    # Cached hash into dot format, or Query result into array of hashes?
    @node.cached_summary['consolidated_descendents'].map {|h| OpenStruct.new(h) }
  end

  def consolidated_transfers
    # This is a lot of transfers. TODO: use it for downstream methods
    # Cached hash into dot format, or Query result into array of hashes?
    @node.cached_summary['consolidated_transfers']
         .map {|h| OpenStruct.new(h) } # TODO: _probably_ want to uses hashes throughout
  end

  def direct_transfers
    desired_depth = @node.is_category? ? 1 : 0

    # Will require adjusting if/when we use hash instead of open struct in consolidated_transfers
    consolidated_transfers.select { |t| t.depth == desired_depth }
  end

  def top_six_as_giver
    @node.cached_summary['top_six_as_giver']
  end

  def top_six_as_taker
    @node.cached_summary['top_six_as_taker']
  end

  def transfers_as_giver
    # TODO: This is an intermediary method I think can be removed
    # maybe put back into money_graphs.rb
    # https://github.com/johnofsydney/lester/pull/73/files#diff-99e8346c873510085b69b3991bf9e3c4ec82ee3944865c89cf1391aa309ce608
    # wherever they go, put less things into cached_summary
    direct_transfers.select { |t| t.direction == 'outgoing' }
  end

  def transfers_as_taker
    # TODO: This is an intermediary method I think can be removed
    direct_transfers.filter { |t| t.direction == 'incoming' }
  end

  def money_in
    @node.cached_summary['money_in']
  end

  def money_out
    @node.cached_summary['money_out']
  end

  def data_time_range
    # quite specific - it is used in graphs
    @node.cached_summary['data_time_range']
  end

  def direct_connections
    @node.cached_summary['direct_connections']
  end

  private

  attr_reader :node
end