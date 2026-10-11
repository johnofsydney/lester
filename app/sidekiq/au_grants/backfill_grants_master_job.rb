# Re-runs monthly to catch any missed days from GrantConnect published-grants data.
# As a backstop, mostly it won't fetch any new data.
# Also used for manual historical backfill.

class AuGrants::BackfillGrantsMasterJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  def perform(date_string = nil)
    target_date = if date_string.present?
                    Date.parse(date_string)
                  else
                    Time.zone.today.last_month.beginning_of_month
                  end

    return if target_date > Time.zone.today

    if queue_overloaded?
      AuGrants::BackfillGrantsMasterJob.perform_in(5.minutes, date_string)
      return
    end

    ingest_day(target_date)

    next_date = target_date + 1.day
    return if next_date > Time.zone.today

    AuGrants::BackfillGrantsMasterJob.perform_in(2.minutes, next_date.to_s)
  end

  private

  def ingest_day(date)
    AuGrants::IngestGrantsByDateJob.perform_async(date.to_s)
  end

  def queue_overloaded?
    Sidekiq::Queue.new(:critical).size > 50 ||
      Sidekiq::Queue.new(:default).size > 2_000 ||
      Sidekiq::Queue.new(:low).size > 2_000 ||
      Sidekiq::Queue.new(:au_grants).size > 2_000
  end
end
