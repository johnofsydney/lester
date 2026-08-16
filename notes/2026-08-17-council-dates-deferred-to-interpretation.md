# Council Membership/Position dates deferred to a future interpretation pass

## Context

A staging spot-check (see `notes/2026-08-15-council-ingestion-production-readiness-goal-2.md`'s
incident) found that even correctly-functioning backfill data "didn't feel right": most NSW
councillors ended up with both a `start_date` *and* an `end_date` on their Membership, and the
associated `Councillor` Position had neither (a separate, smaller bug -- see below). Looking past
the immediate bugs, the deeper problem was the premise: **election-results data alone cannot tell
us when a councillor actually started.** A councillor re-elected in 2024 who also won in 2021 might
have first been elected in 2016, 2012, or earlier -- cycles this pipeline doesn't (and may never)
reach. Recording `start_date: <most recent declared-elected date>` looks precise but overstates
what we actually know.

## Decision

`Councils::{Nsw,Vic}::ImportCouncilResultRowJob` no longer records `start_date`/`end_date` on any
Membership or Position it creates. It still creates the (now permanently undated) Councillor
Membership/Position and party-affiliation Membership -- "this person is/was a councillor of this
council" remains a fact worth having in the graph today. What changes is that the *dated* fact
("declared elected to this council in this cycle") is recorded separately, as raw data on the
Person, not baked into the Membership.

This mirrors a pattern already established in this codebase for federal politicians:
`Person#open_australia_data` stores OpenAustralia's raw Terms, and a separate
`OpenAustralia::Interpretation::RecordMembershipsAndPositions` pass derives dated
Memberships/Positions from it (ADR-0001 documents the raw-data-separate-from-interpretation split).
Councils now follow the same shape, with one structural difference:

**Councils append, OpenAustralia overwrites.** OpenAustralia's raw Terms are safe to overwrite on
every fetch (ADR-0001) because one API call returns a person's *entire* known history in one shot.
Council data arrives piecemeal -- each import run only tells us about one election's result for
one council, discovered incrementally across many separate runs (including runs against different
cycles, months or years apart). `Person#council_election_data` (new `jsonb`, default `[]`) is
therefore append-only, via `People::RecordCouncilElectionData`, deduped on
`(state, council_slug, cycle)` so idempotent re-runs of the same council/cycle don't create
duplicate entries.

Each observation: `state`, `council_name`, `council_slug`, `cycle` (NSW: `LG2401`-style election
id; VIC: year), `declared_date`, `party` (NSW only), `source_url`. `declared_date` still applies
VIC's existing election_date override for non-latest cycles (VEC's archived "Last updated" stamp
is unreliable -- see `notes/2026-08-15-...`) -- that override was never about Membership dates
specifically, it's about recording the best available date in the raw data at all.

## What this removes

- `close_departed_members` (both NSW and VIC import jobs) -- gone entirely. Without dates, we're
  not confident enough in "this person departed" to act on it either; a former councillor's
  Membership just stays open (undated) until a future interpretation pass can derive it properly.
  This means the graph will over-show people as current councillors until interpretation exists --
  an accepted, explicit trade-off, not an oversight.
- `backfill_end_date` and the whole "does this person already have an open membership" continuity
  check -- no longer needed, since there's no end_date to decide whether to set.
- `Councils::{Nsw,Vic}::Elections.next` -- was only used by the above. `latest?`/`election_date`
  remain (VIC still needs the declared_date override; NSW's `election_date` field stays as
  reference metadata even though nothing reads it yet).

## Consequence: run order no longer matters

The whole "current cycle must be imported before backfill" constraint from
`notes/2026-08-15-...`/`notes/council-ingestion-run-order.md` existed only because
`backfill_end_date` needed to check for an already-open Membership to decide continuity. With no
dates and no close-out logic, `Group::RecordRow`'s dedup (matching on *any* open Membership,
regardless of when it was created) makes the backfill and current-cycle imports fully
order-independent. `notes/council-ingestion-run-order.md` has been updated accordingly.

## Also fixed in passing

The Position-has-no-dates bug that prompted this whole discussion (`Group::RecordRow` created a
Position but never set its `start_date`/`end_date` to match the Membership) is moot now that
neither has dates -- but the underlying fix (mirroring Position dates onto Membership, always in
sync, including through `close_departed_members`) already shipped and remains correct for any
*other* future caller of `Group::RecordRow` that does pass dates (there are none today, but the
mechanism is generically correct).

## Deferred: the interpretation pass

Not built yet. Once enough historical depth exists (see the "how far back" discussion in
`notes/2026-08-15-...`) to derive real tenure dates with confidence, a
`Councils::Interpretation::RecordMembershipsAndPositions`-style service (mirroring OpenAustralia's)
would read `Person#council_election_data` and populate real `start_date`/`end_date` values. Until
then, council Membership/Position dates are simply absent, not approximated.

## Verification

- `bundle exec rspec spec/services/people/record_council_election_data_spec.rb spec/sidekiq/councils/ spec/tasks/maintenance/ spec/services/councils/ spec/services/group/record_row_spec.rb`
  -- 102 examples, 0 failures.
- `bundle exec rubocop` clean on all touched files.
- Migration: `db/migrate/20260817080000_add_council_election_data_to_people.rb` (adds
  `people.council_election_data` jsonb + `council_election_data_updated_at`).
