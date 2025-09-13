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