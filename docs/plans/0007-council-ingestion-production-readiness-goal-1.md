# Council Ingestion — Production Readiness, Goal 1 (Full ingest, current cycle)

**Status:** Implemented

## Context

`docs/plans/0002-local-council-councillor-ingestion.md` covers what already shipped: working NSW + VIC per-council import jobs, fanned out from an index-discovery job, using `rand(1..60).seconds` jitter designed for a small pilot run. Before running this for real across every council in both states, three gaps needed resolving. This doc covers the first: spacing, trigger mechanism, and success criteria for the initial full-scale run. (Goals 2 and 3 — historical backfill and scheduling — are separate, later docs.)

## Decisions

**Spacing.** Replaced `rand(1..60).seconds` with an explicit incrementing delay: `council_index * 90.seconds`, added as an `IMPORT_SPACING` constant on both `Councils::Nsw::IngestElectionResultsJob` and `Councils::Vic::IngestElectionResultsJob`. This guarantees a deterministic ≥90s gap between requests to each commission's site, rather than relying on randomness that could still cluster. Modelled on the incrementing-delay pattern already used by `AusTender::BackfillContractsMasterJob`, minus its self-rescheduling/queue-depth-backstop machinery — not needed here since the whole fan-out is enqueued in one shot up front, not walked incrementally.

Confirmed live council counts via `Councils::{Nsw,Vic}::ResultsIndexParser`: **NSW 128**, **VIC 78**. At 90s spacing that's ~3.2 hours end-to-end for NSW, ~2 hours for VIC (both states run concurrently since they're independent job classes hitting different domains).

**Trigger.** One-off console call — `Councils::Nsw::IngestElectionResultsJob.perform_async` / `Councils::Vic::IngestElectionResultsJob.perform_async` — no rake task. This is expected to be the last manual run; Goal 3 will wire the same jobs into `sidekiq-scheduler`, so a throwaway rake task would be redundant almost immediately.

**Retry.** No change — `Councils::{Nsw,Vic}::ImportCouncilResultRowJob` already carries `retry: 3` from the earlier pilot, which covers the known transient-Cloudflare-500 case. Combined with 90s spacing, this should not add meaningful additional load to either commission's site during retries.

## Success criteria for the run

After triggering both jobs and letting them finish (~3-4 hours):

- `Group.local_councils_tag.groups.count` — expect up to 128 + 78 = 206, but likely fewer: some councils already exist as `Group` records from AusTender contract data under the same name and will be reused rather than duplicated (`Groups::RecordGroup` disambiguates by name).
- `Membership` rows with `start_date` in 2024 and `evidence` citing "NSW Electoral Commission" / VIC's equivalent — spot-check a handful of at-large and ward-divided councils (e.g. Albury vs. Blacktown) to confirm both parsing paths worked at scale.
- `ApiLog` rows for either job's endpoints — ideally none; any that exist should correspond to retries that ultimately succeeded (check the council was still imported) rather than a council silently dropped after exhausting retries.
- Undeclared contests: any council/ward not yet declared at run time is expected to simply be absent from this run's results (by design — see the governing doc's "wait for every contest to declare" note for NSW). Confirm this reads as "no data yet," not as an error, for any such council.
- Browse `/admin/groups` filtered to "Australian Local Councils" and `/admin/memberships` for a couple of pilot councils to confirm the data reads sensibly through existing admin screens.

## Rollout status

Code changes complete and spec-covered (`spec/sidekiq/councils/{nsw,vic}/ingest_election_results_job_spec.rb` — existing assertions on `kind_of(ActiveSupport::Duration)` needed no changes). The full-scale run itself has not been triggered yet — held pending a deliberate go-ahead, since it's a production-writing, real-external-site-hitting action.
