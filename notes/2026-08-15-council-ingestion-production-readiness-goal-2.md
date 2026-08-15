# Council Ingestion — Production Readiness, Goal 2 (Backfill older election cycles)

## Context

Follows Goal 1 (`context/2026-08-11-...`) and Goal 3 (`context/2026-08-12-...`). This removes the
hardcoded `ELECTION_ID`/`ELECTION_YEAR` constants from `Councils::{Nsw,Vic}::ImportCouncilResultRowJob`
and `Councils::{Nsw,Vic}::IngestElectionResultsJob`, parameterizing them to accept an election
cycle, and adds a backfill of the one prior cycle confirmed reachable in each state.

## Live research findings (not assumptions)

Before designing anything, fetched real URLs against both commissions' sites:

- **NSW**: only two cycles use the current `pastvtr.elections.nsw.gov.au/LG<id>/` site structure —
  `LG2401` (2024, current) and `LG2101` (Dec 2021, the COVID-postponed cycle). Older cycles (2016,
  2012, 2008, 2017) live under a structurally different legacy site (`LGE<year>/`) with different
  HTML — not parseable by the existing code. Confirmed `LG2101`'s index parses with
  `Councils::Nsw::ResultsIndexParser` (128 councils, identical slug list to 2024 — **no
  amalgamation mismatches for this specific pair**), and a sample council's contest page parses
  correctly with the real 2021 declared date intact (`Councils::Nsw::CouncillorResultsParser`
  reads "declared elected on \<date>" text baked into the archived page itself, not a
  regeneration timestamp — reliable for backfill).
- **VIC**: same shape — only `2024-council-election-results` and `2020-council-election-results`
  use the modern structure; older cycles are legacy-skinned. Confirmed `2020`'s index parses (76
  councils) and a sample council's page parses structurally. **But**: `Councils::Vic::CouncillorResultsParser`
  reads a page-level "Last updated" stamp as `declared_date`, not a per-council declaration date.
  Fetched several real 2020 council pages live — every one reports `Last updated: 22 November 2024`,
  clearly a site-wide republish timestamp from whenever VEC last regenerated the archive, not the
  real Oct/Nov 2020 declaration. Using it unmodified would have silently written **2024** as the
  start_date for 2020-term councillors.
- **Scope decision**: backfill one extra cycle each (NSW 2021, VIC 2020) only. Going further back
  needs a second parser generation against a structurally different legacy site, plus real NSW
  amalgamation-mapping work (2016 amalgamations predate both older-legacy cycles) — explicitly out
  of scope for this phase, flagged here as a future phase if ever wanted.

## Design

**`Councils::Nsw::Elections` / `Councils::Vic::Elections`** (`app/services/councils/{nsw,vic}/elections.rb`) —
small lookup modules holding the known cycles oldest-first, each with an `election_date` (the
state-wide polling day) plus NSW's `id`/VIC's `year` key. `.latest`, `.latest?(id_or_year)`,
`.find(id_or_year)`, `.next(id_or_year)`.

**Parameterization**: `IngestElectionResultsJob#perform(election_id = Elections.latest[:id])` (NSW)
/ `#perform(election_year = Elections.latest[:year])` (VIC), threaded through to
`ImportCouncilResultRowJob#perform(council_name, council_slug, election_id/year = Elections.latest[...])`.
Existing scheduler entries in `config/sidekiq.yml` call both `IngestElectionResultsJob`s with no
args, so they continue running the latest (2024) cycle unchanged — no config changes needed for
Goal 2 to land safely alongside Goal 3's monthly cron.

**VIC declared_date override**: for any non-latest cycle, `declared_date` is the cycle's known
`election_date` instead of the page's broken "Last updated" stamp; the latest cycle keeps trusting
the (accurate, because current) page value. NSW needs no such override — its dates are read from
the archived page's own content and were confirmed correct for 2021.

**Fixed the close-out ordering bug**: `close_departed_members` now only ever runs for the latest
known cycle (`Elections.latest?(...)`), for both states. Without this, backfilling 2021/2020 after
2024 was already live (which it is — Goal 1 already ran) would have read today's 2024 councillors
as "not returned" in the older election and incorrectly closed their memberships using the older
declared date.

**Backfill close-out (`backfill_end_date`)**: guarding close-out for backfill runs would otherwise
leave one-term-only backfilled councillors (served 2021/2020, didn't continue to 2024) with a
permanently open membership, since nothing else would ever close them out. Fix: for a non-latest
cycle, before calling `Group::RecordRow`, check whether the person already has an open membership
on that council. If they do, they continued serving — leave it alone (their real end_date, if any,
belongs to a later cycle's own close-out). If they don't, their absence from 2024's results proves
they didn't continue — pass `end_date: Elections.next(this_cycle)[:election_date]` so the newly
created backfill membership is born already closed. **This relies on the latest cycle already
being imported** — true today, and consistent with the brief's own recommended Goal 1 → Goal 3 →
Goal 2 ordering.

## Verification

- `bundle exec rspec spec/sidekiq/councils/` — 32 examples, 0 failures. Added coverage for: the
  three backfill scenarios above (unrelated existing membership left alone, new backfill
  membership closed via next-cycle date, continuing member's existing membership untouched) for
  both NSW and VIC, plus VIC's declared_date override.
- `bundle exec rubocop` — clean on all touched files.
- Not yet run against production data — this is code-only; no backfill job has been triggered yet.
