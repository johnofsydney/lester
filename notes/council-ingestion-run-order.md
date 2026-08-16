# Council ingestion — run order

How to (re-)populate NSW/VIC council election data from scratch (e.g. after a DB restore). Order
matters — running the backfill before the current cycle produces wrong data (see
`notes/2026-08-15-council-ingestion-production-readiness-goal-2.md`'s "backfill_end_date" section).

## 1. Current cycle first

```ruby
Councils::Nsw::IngestElectionResultsJob.perform_async   # defaults to the latest cycle (LG2401/2024)
Councils::Vic::IngestElectionResultsJob.perform_async    # defaults to the latest cycle (2024)
```

Wait for these to fully drain from the `:low` Sidekiq queue before moving on -- roughly 3.2 hours
for NSW (128 councils), 2 hours for VIC (78 councils), run concurrently. Check Sidekiq Web's
`:low` queue size, or spot-check via `Membership.where(start_date: Date.new(2024,1,1)..).count`
climbing toward the expected totals.

**Why first:** `Councils::{Nsw,Vic}::ImportCouncilResultRowJob#backfill_end_date` decides whether a
backfilled (older-cycle) councillor continued serving by checking for an already-open membership
on that council. If the current cycle hasn't been imported yet, that check always says "no" --
the backfill would then incorrectly close out every single councillor as a one-term departure,
even people still serving today. This happened once already on staging (see
`notes/2026-08-15-...` and the conversation it was caught in) -- 1,182 of 1,784 NSW memberships
were wrongly closed because the backfill ran with zero 2024 data in the DB.

## 2. Then the backfill

From `/maintenance_tasks`, start a run of:
- `Maintenance::BackfillNswCouncilElectionResultsTask` (backfills `LG2101`/2021)
- `Maintenance::BackfillVicCouncilElectionResultsTask` (backfills 2020)

These just enqueue `ImportCouncilResultRowJob` for every council in the older cycle (spaced the
same way as the primary ingest) -- the task itself finishes in seconds, but the real import work
runs asynchronously via Sidekiq afterward. Check Sidekiq Web's dead-set for any councils that
exhausted retries rather than the task's own progress bar, which only reflects "enqueued."

## Known NSW/VIC exceptions (not errors)

A council with no contest table on its results page isn't necessarily broken --
`Councils::Nsw::ResultsPageParser.no_contest_expected?` already treats these as expected,
zero-record skips:
- In administration that cycle (council dismissed, run by an appointed administrator instead)
- Runs its own election under s296 of the Local Government Amendment (Elections) Act 2011 --
  NSWEC never has data for these councils, in any cycle (e.g. Fairfield, Liverpool)

## Ongoing (no action needed)

Once both cycles are in, `config/sidekiq.yml`'s `ingest_nsw_council_election_results_job` /
`ingest_vic_council_election_results_job` cron entries re-run the *current* cycle monthly,
idempotently -- no need to re-run anything manually going forward, except a future backfill if we
ever extend coverage further back (see the "known limitation" section of
`notes/2026-08-15-council-ingestion-production-readiness-goal-2.md`).
