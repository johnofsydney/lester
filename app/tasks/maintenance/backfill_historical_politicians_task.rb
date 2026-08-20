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
    # Sidekiq's own machinery instead of halting the task run.
    #
    # The delay is spaced by an instance-level counter, not a flat SPACING for every item --
    # job-iteration reuses one Task instance for every #process call within a single job
    # execution (a batch), calling it in a tight loop, so a flat delay would make a whole batch
    # due at the same instant instead of trickling out. The counter deliberately does NOT track
    # this item's position in the full 1..max_person_id range: that would accumulate into a very
    # long delay for anything resumed after this task is paused from the maintenance_tasks UI.
    # Restarting the counter at 0 for every new job execution/batch keeps each batch internally
    # polite without assuming anything about how much of the run has happened before it.
    def process(person_id)
      OpenAustralia::IngestPersonJob.perform_in(next_delay, person_id)
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

    private

    def next_delay
      @item_count = (@item_count || 0) + 1
      @item_count * SPACING
    end
  end
end
