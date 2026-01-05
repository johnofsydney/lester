# This file can be deleted when all of the contracts have been ingested

class BackfillContractsMasterJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  def perform(date_string)
    target_date = Date.parse(date_string)
    return if target_date > Date.today

    # ----- Overload protection (optional but recommended) -------
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
