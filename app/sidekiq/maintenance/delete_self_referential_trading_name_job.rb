class Maintenance::DeleteSelfReferentialTradingNameJob
  include Sidekiq::Job

  sidekiq_options queue: :low,
                  lock: :until_executed,
                  on_conflict: :log,
                  retry: 3

  # Re-checks the condition at execution time: a row deleted or renamed since enqueue
  # is skipped rather than destroyed on stale information.
  def perform(trading_name_id)
    trading_name = TradingName.duplicating_owner_name.find_by(id: trading_name_id)
    return unless trading_name

    trading_name.destroy!
  end
end
