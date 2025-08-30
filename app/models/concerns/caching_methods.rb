module CachingMethods
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  included do
    # Ensure :cached_data is a JSON or text column in your model's table.
    # This creates getter/setter methods for :cached_direct_consolidated_transfers on the model.
    store_accessor :cached_data, :cached_direct_consolidated_transfers
  end

  # amount, effective_date, depth, direction, giver_id, giver_type, taker_id, taker_type
  def direct_consolidated_transfers
    if use_cached_data?(:direct_consolidated_transfers)
      cached_direct_consolidated_transfers.map { |hash| RehydratedTransfer.new(hash) }
    else
      # fetch database records and transform into hash for caching
      results = self.consolidated_transfers(depth: 0).map(&:to_h)
      # update the cache with results
      self.update(last_cached: Time.current, cached_direct_consolidated_transfers: results)
      # return hydrated transfer objects as an array
      results.map { |hash| RehydratedTransfer.new(hash) }
    end
  end

  def outgoing_transfers_cached
    outgoing_transfers
  end

  private

  def use_cached_data?(key)
    case key
    when :direct_consolidated_transfers
      cached_direct_consolidated_transfers.present? && cache_fresh?
    end
  end

  def cache_fresh?
    last_cached.present? && last_cached > 15.minutes.ago
  end
end