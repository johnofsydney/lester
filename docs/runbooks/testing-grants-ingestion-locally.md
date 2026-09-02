# Testing grants ingestion locally

How to exercise the GrantConnect pipeline (`docs/plans/0005-ingest-grants-design.md`) against real
data in a local dev environment, in increasing order of scale.

Prerequisite: `bin/dev` running (or at least a `bundle exec sidekiq` worker) so jobs on the
`au_grants` queue actually get picked up — `config/sidekiq.yml` registers this queue.

## Tier 1 — single day

In `rails console` (or `bin/rails runner`):

```ruby
AuGrants::IngestGrantsByDateJob.perform_async('2026-01-05')
```

Watch Sidekiq Web (`/sidekiq`) for the `au_grants` queue draining. Then inspect:

```ruby
IndividualTransaction.government_grants.count
IndividualTransaction.government_grants.last(5).map { |t| [t.external_id, t.giver.name, t.taker.name, t.amount] }
Transfer.government_grants.count
```

Spot-check one grant in the running app: find the recipient Group's show page and confirm the
grant appears with the right amount/agency/date. Cross-check the amount and agency against
`https://www.grants.gov.au/Ga/Show/{GA_ID}` for at least one row.

## Tier 2 — small range of days (e.g. a week)

```ruby
(Date.new(2026, 1, 5)..Date.new(2026, 1, 11)).each do |date|
  AuGrants::IngestGrantsByDateJob.perform_async(date.to_s)
end
```

Same checks as Tier 1, plus:
- Confirm no duplicate `IndividualTransaction`s (`external_id` dedup) if any date overlaps a
  previous run
- Confirm `Transfer` rollups aggregate correctly across multiple days landing in the same
  financial year for the same agency/recipient pair (`Transfer.government_grants.where(giver: ..., taker: ...)`
  should still be a single row per FY)
- Check Sidekiq's dead set for any failures (bad ABNs, unexpected column values, etc.)

## Tier 3 — larger range (e.g. a month or more)

Use `AuGrants::BackfillGrantsMasterJob` rather than looping manually — it walks day-by-day and
respects queue-depth backoff:

```ruby
AuGrants::BackfillGrantsMasterJob.perform_async('2026-01-01')
```

This chains itself forward one day at a time (2 minute spacing) until it reaches
`Time.zone.today`, so a month will take a while in real time — that spacing exists to avoid
hammering GrantConnect, not because of local resource limits. For a faster local-only check, drive
the date loop manually as in Tier 2 but across the full range, or temporarily lower the
`2.minutes`/`5.minutes` delays in the job while testing (revert before committing).

At this scale, also check:
- Whether `GaPublishedDownload` ever returns versioned GA IDs (`-V1`, `-V2`) in practice — open
  question #2 in the design doc
- Rough aggregate-vs-confidential skip rate (`Rails.logger` or a quick console tally) to sanity
  check those v1 exclusions aren't silently dropping most of the data
- GrantConnect rate-limiting behaviour under repeated requests — currently untested; if 429s show
  up, the design doc's "Rate limiting / resilience" section has the fallback plan

## After each tier

Assess before moving to the next tier:
- Did the pipeline run without unexpected errors?
- Does the data in the running app look right for known cases?
- Any schema/enum/association surprises (e.g. the `fine_grained_transaction_category`
  required-association issue already resolved in the design doc)?
