# Council ingestion — run order

How to (re-)populate NSW/VIC council election data from scratch (e.g. after a DB restore).

**Order no longer matters for correctness.** As of `docs/adr/0006-council-membership-position-dates-deferred-to-interpretation.md`,
`Councils::{Nsw,Vic}::ImportCouncilResultRowJob` records no `start_date`/`end_date` at all on
Membership/Position -- it just ensures the (undated) Membership exists, and appends a raw dated
observation to `Person#council_election_data`. `Group::RecordRow`'s dedup (matching on an *open*
Membership) no longer depends on dates either, so running the backfill before the current cycle
(or vice versa) produces the same end state either way. This replaces an earlier version of this
runbook where sequencing was correctness-critical -- see that doc for the incident that motivated
removing dates from this pipeline entirely.

Any order below is fine; current-cycle-first is still the natural default.

## Current cycle

```ruby
Councils::Nsw::IngestElectionResultsJob.perform_async   # defaults to the latest cycle (LG2401/2024)
Councils::Vic::IngestElectionResultsJob.perform_async    # defaults to the latest cycle (2024)
```

Roughly 3.2 hours for NSW (128 councils), 2 hours for VIC (78 councils), run concurrently via the
`:low` Sidekiq queue.

## Backfill

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

`config/sidekiq.yml`'s `ingest_nsw_council_election_results_job` /
`ingest_vic_council_election_results_job` cron entries re-run the *current* cycle monthly,
idempotently -- no need to re-run anything manually going forward, except a future backfill if we
ever extend coverage further back (see the "known limitation" section of
`docs/plans/0009-council-ingestion-production-readiness-goal-2.md`).
