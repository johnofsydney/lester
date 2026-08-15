# Council Ingestion — Production Readiness, Goal 3 (Scheduled job for fresh results)

## Context

Follows `context/2026-08-11-council-ingestion-production-readiness-goal-1.md`. Goal 3 wires `Councils::{Nsw,Vic}::IngestElectionResultsJob` into `sidekiq-scheduler` so re-runs happen without manual triggering, per the recommended Goal 1 → Goal 3 → Goal 2 order in the original brief (Goal 3 needed no changes to the underlying import logic, just scheduling — Goal 1's fan-out/spacing work already proved the pipeline at full scale).

## Decisions

**Error visibility.** No new mechanism added. The existing `rescue → ApiLog.create → raise` pattern (unchanged from the original design) is the same one `Acnc::IngestDatasetCsvJob`, `AuLobbyists::IngestLobbyistsJob`, and `AusTender::IngestContractsDateJob` already run under `sidekiq-scheduler` in production today. New Relic (already in the stack, `config/newrelic.yml`) captures exceptions raised out of Sidekiq jobs automatically, so a raised-and-retried-out error surfaces there without any bespoke alerting. There's no reason council ingestion needs a stricter bar than every other scheduled ingestion job in this repo.

**Cadence.** Monthly, matching the coarse-grained cadence already used by every other cron entry in `config/sidekiq.yml` (ACNC, lobbyists, AusTender's backfill). Added two new `:scheduler` entries:
- `ingest_nsw_council_election_results_job` — 3rd of the month, 23:00 AEST
- `ingest_vic_council_election_results_job` — 4th of the month, 23:00 AEST (staggered a day apart from NSW, no particular reason beyond avoiding both full ~2-4hr fan-outs starting at the exact same moment)

Both jobs (and their per-council import jobs) were also moved onto the existing `:low` Sidekiq queue (`sidekiq_options queue: :low`), matching `AusTender::BackfillContractsMasterJob`'s convention for backstop/re-validation work that isn't time-sensitive.

**Known limitation — does NOT cover the 2028 election.** `Councils::Nsw::ImportCouncilResultRowJob::ELECTION_ID` (`'LG2401'`) and `Councils::Vic::ImportCouncilResultRowJob::ELECTION_YEAR` (`2024`) are still hardcoded to the current cycle. This monthly cron entry will keep re-fetching **2024** results indefinitely — it will not automatically start pulling 2028 results when that election happens. What it actually buys us:
- Near-term: catches any wards/councils that hadn't declared yet on the initial Goal 1 full run (NSW's `close_departed_members` guard explicitly waits for every contest to declare, so late declarations need a follow-up run to get picked up and closed out correctly).
- Long-term: a cheap, idempotent, indefinite backstop/re-validation once 2024 results are fully settled — low value but harmless.

Real 2028 coverage requires the election-id/year to become parameterized (or the constants manually bumped) before then — that's Goal 2's territory (`context/2026-07-28-local-council-councillor-ingestion.md`'s backfill design), not solved by this scheduler entry. Flagging this explicitly now so it isn't silently assumed solved.

## Status

Code changes complete: `queue: :low` added to all four job classes, two monthly cron entries added to `config/sidekiq.yml`. No spec changes needed (scheduler config isn't exercised by the job specs; `sidekiq_options` queue is not asserted anywhere in existing specs).
