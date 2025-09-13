module CachedMethods
  extend ActiveSupport::Concern

  def cached
    RehydratedNode.new(self)
  end
end

class RehydratedNode
  def initialize(node)
    @node = node
  end

  def consolidated_descendents
    cached_value = @node.cached_summary&.[]('consolidated_descendents')

    if cached_value.present? && cache_fresh?
      cached_value
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