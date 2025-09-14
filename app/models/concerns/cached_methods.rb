module CachedMethods
  extend ActiveSupport::Concern

  def cached
    RehydratedNode.new(self)
  end
end

class RehydratedNode
  # It should be OK to have methods in here with same names the group or person (or it's mixins) - the namespace should protect us from ambiguity.
  def initialize(node)
    @node = node
  end

  def consolidated_descendents
    # This is a lot of descendents. TODO: use it for downstream methods
    # TODO: decide which to coerce?
    # Cached hash into dot format, or Query result into array of hashes?
    cached_value = @node.cached_summary&.[]('consolidated_descendents')

    if cached_value.present? && cache_fresh?
      cached_value.map {|h| OpenStruct.new(h) }
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.consolidated_descendents(depth: 5)
    end
  end

  def top_six_as_giver
    cached_value = @node.cached_summary&.[]('top_six_as_giver')

    if cached_value.present? && cache_fresh?
      cached_value
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.top_six_as_giver
    end
  end

  def top_six_as_taker
    cached_value = @node.cached_summary&.[]('top_six_as_taker')

    if cached_value.present? && cache_fresh?
      cached_value
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.top_six_as_taker
    end
  end

  def transfers_as_giver
    cached_value = @node.cached_summary&.[]('transfers_as_giver')

    if cached_value.present? && cache_fresh?
      cached_value
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.transfers_as_giver
    end
  end

  def transfers_as_taker
    cached_value = @node.cached_summary&.[]('transfers_as_taker')

    if cached_value.present? && cache_fresh?
      cached_value
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.transfers_as_taker
    end
  end

  def money_in
    cached_value = @node.cached_summary&.[]('money_in')

    if cache_fresh?
      # skipping the present? check as nil is a valid value
      cached_value
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.money_in
    end
  end

  def money_out
    cached_value = @node.cached_summary&.[]('money_out')

    if cache_fresh?
      # skipping the present? check as nil is a valid value
      cached_value
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.money_out
    end
  end

  def data_time_range
    # quite specific - it is used in graphs
    cached_value = @node.cached_summary&.[]('data_time_range')

    if cached_value.present? && cache_fresh?
      cached_value
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.data_time_range
    end
  end

  def direct_connections
    cached_value = @node.cached_summary&.[]('direct_connections')

    if cached_value.present? && cache_fresh?
      cached_value
    else
      cache_builder.set(wait: 60.seconds).perform_async(node.id)
      node.direct_connections
    end
  end

  private

  attr_reader :node

  def cache_fresh?
    return false unless node.cached_summary_timestamp

    node.cached_summary_timestamp > 1.week.ago
  end

  def cache_builder
    node.is_a?(Person) ? BuildPersonCachedDataJob : BuildGroupCachedDataJob
  end
end