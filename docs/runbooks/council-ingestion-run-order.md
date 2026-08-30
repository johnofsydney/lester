# Council ingestion — run order

How to (re-)populate NSW/VIC/QLD council election data from scratch (e.g. after a DB restore).

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

## QLD

One command covers everything -- current cycle, historical backfill, and every by-election since
2020 -- since QLD's source (`resultsdata.elections.qld.gov.au`) is a single live index rather than
a per-cycle page to crawl (see `docs/plans/0012-qld-council-councillor-ingestion.md`). No separate
backfill maintenance task, unlike NSW/VIC.

```ruby
Councils::Qld::IngestElectionResultsJob.perform_async
```

This discovers all ~45 QLD local elections (2 general elections + every by-election), fans out one
`ImportElectionResultsJob` per election (spaced 5s apart), each of which fans out one
`RecordContestResultJob` per contest (~343 for a general election, usually 1 for a by-election).
All async via the `:low` Sidekiq queue -- the console call itself returns almost immediately.

**Requires Sidekiq actually running** to process anything -- `bin/dev` starts it via
`Procfile.dev`'s `worker: bundle exec sidekiq` process; a plain `rails s`/`rails c` alone won't
drain the queue.

There's no maintenance task UI for this (by design -- see the plan doc's "one mechanism, not
three" rationale), so check progress via Sidekiq Web's dead-set rather than a progress bar.

### Spot-checking against source

Cross-check any council's declared result against ECQ's own results site:
- General election: `https://results.elections.qld.gov.au/2024QLGE` -- pick a council from the
  list, e.g. Brisbane City for a contested/party-affiliated mayoral race.
- Full election index (state + local, including every by-election): `https://www.ecq.qld.gov.au/elections/election-results`

The underlying JSON these pages render from -- what the pipeline itself reads -- is also directly
browsable, e.g. `https://resultsdata.elections.qld.gov.au/2024QLGE-declared_candidates.json`.
