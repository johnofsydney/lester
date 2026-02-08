# When originally written this was to backfill historical data from AusTender contracts master data.
# Re-purposing to run monthly to ensure any missed days are ingested.
# As this is a backstop, mostly it won't fetch any new data.

class BackfillContractsMasterJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  def perform(date_string = nil)
    target_date = if date_string.present?
      Date.parse(date_string)
    else
      Date.today.last_month.beginning_of_month
    end

    return if target_date > Date.today

    # ------------------- Overload protection ---------------------
    if queue_overloaded?
      BackfillContractsMasterJob.perform_in(5.minutes, date_string)
      return
    end

    ingest_day(target_date)

    next_date = target_date + 1.day
    return if next_date > Date.today

    # Schedule next day in 2 minutes
    BackfillContractsMasterJob.perform_in(2.minutes, next_date.to_s)
  end

  private

  def ingest_day(date)
    # Your existing ingest process
    IngestContractsDateJob.perform_async(date.to_s)
  end

  def queue_overloaded?
    Sidekiq::Queue.new(:critical).size > 50 ||
      Sidekiq::Queue.new(:default).size > 2_000 ||
      Sidekiq::Queue.new(:low).size > 2_000 ||
      Sidekiq::Queue.new(:aus_tender_contracts).size > 2_000
  end
end
