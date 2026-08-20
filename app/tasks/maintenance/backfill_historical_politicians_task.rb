# Sweeps every OpenAustralia person_id from 1 up to the highest id currently seen on the live
# roster, so that people who served at any point in the last 50 years (ADR 0004) get ingested,
# not just currently-serving politicians (see docs/plans/0004-ingest-federal-politicians-design.md,
# Increment 4). OpenAustralia::IngestPerson already fetches a person's full Term history
# regardless of how the id was discovered, and already no-ops for ids with no data or with no
# terms inside the 50-year window -- this task is purely the id-sweep driver.
module Maintenance
  class BackfillHistoricalPoliticiansTask < MaintenanceTasks::Task
    SPACING = 2.seconds

    def collection
      (1..self.class.max_person_id).to_a
    end
    delegate :count, to: :collection

    # Enqueues rather than ingesting inline, so a single id's failure retries and dead-letters via
    # Sidekiq's own machinery instead of halting the task run. A flat per-item delay (not one
    # accumulated off this id's position in the range) is deliberate -- this task can be paused
    # and resumed from the maintenance_tasks UI, and an accumulating delay computed relative to
    # run start would over- or under-delay whatever resumes after a pause.
    def process(person_id)
      OpenAustralia::IngestPersonJob.perform_in(SPACING, person_id)
    end

    # Memoized at the class level, not the instance level: job-iteration calls #collection fresh
    # on every batch of this run (each batch gets a new Task instance), so an instance-level memo
    # would hit the live roster API on every batch, and a roster change mid-run would change
    # #collection's size between batches -- which can break cursor-based resumption. A class-level
    # memo computes this once per Sidekiq process lifetime; a redeploy mid-run just picks up a
    # fresh number, which is an accepted tradeoff (see the design doc).
    def self.max_person_id
      @max_person_id ||= OpenAustralia::MaxKnownPersonId.call
    end
  end
end
