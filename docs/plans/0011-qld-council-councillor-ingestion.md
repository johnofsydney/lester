# QLD Council Councillor Ingestion

**Status:** Draft — not yet implemented

## Context

Follows `docs/plans/0002-local-council-councillor-ingestion.md` (NSW + VIC) and the Goal 1/2/3
production-readiness docs (`0007`–`0009`). Same intent as those: ingest declared local-government
election results as Person/Membership/Position records, sourced from the state electoral
commission. QLD's source is a different shape, so the mechanics differ even though the outcome
(a `Councils::Qld` namespace mirroring `Councils::Nsw`/`Councils::Vic`) should look familiar.

## The source

QLD publishes results through an Angular SPA at `results.elections.qld.gov.au/<stub>` (e.g.
`/2024QLGE`). The page itself is JS-rendered and has no scrapable HTML — but it's a thin client
over a **public static JSON API** at `resultsdata.elections.qld.gov.au`, found by reading the
app's compiled bundle (`main.<hash>.js`) for its `environment.ts` config:

```
https://resultsdata.elections.qld.gov.au/elections.json
https://resultsdata.elections.qld.gov.au/<stub>-electorates.json
https://resultsdata.elections.qld.gov.au/<stub>-declared_candidates.json
```

This is a materially better source than NSW/VIC in three ways:

1. **One index, every election.** `elections.json` lists all 55 QLD elections since 2020 (state
   and local, general and by-election) with a `stub`, `electionType`, `electionDay`, and
   `current`/`visible` flags — no separate "find the list of councils" step, no separate index
   page per cycle. Filtering `electionType` to `Local Quadrennial` / `Local Councillor By-election`
   / `Local Mayoral By-election` gives all 45 QLD local elections in one request: the 2020 and 2024
   general elections *and every by-election run since*, already correctly typed.
2. **By-elections are first-class, not a gap.** NSW/VIC's plan explicitly deferred by-election
   tracking (`0002` line 53). QLD's index makes every by-election trivially discoverable and
   identically shaped to the general elections — no reason to defer it here.
3. **No index-then-per-council-page fan-out.** `<stub>-declared_candidates.json` for a given
   election already contains every council/division/mayoral contest's declared result in one file
   (343 entries for `2024QLGE`). There's no NSW/VIC-style "fetch council index page, then fetch
   each council's results page, then fetch each ward's results page" chain — the whole cycle's
   results are one HTTP GET.

### Data shape

`<stub>-declared_candidates.json` — one entry per contest (mayoral or per-division councillor):

```json
{
  "electorateId": 566,
  "areaCode": "008",
  "eventName": "2024 Local Government Elections",
  "pollingDate": "2024-03-16T00:00:00.000Z",
  "declarationDate": "02 Apr 2024",
  "contest": "mayor",
  "declaredCandidate": "SCHRINNER, Adrian Jurgen",
  "declaredCandidateParty": "Liberal National Party of Queensland",
  "declaredCandidatePartyCode": "LNP"
}
```

Councillor (multi-member division) contests use a `declaredCandidates` array of
`{ declaredCandidate, declaredCandidateBallotOrder }` instead of the singular field — no party on
these in the sample seen so far, worth confirming across more councils.

**Join, confirmed.** `<stub>-electorates.json`'s `electorates` array is flat, not nested as it
first appears — a divided council's per-division records are duplicated as their own top-level
array entries (with their own `electorateId`, and `parentElectorateId` pointing back to the
council), in addition to appearing inside the council's `divisions[]` for ballot-drawing purposes.
So `declared_candidates.json[].electorateId` joins directly and uniquely onto
`electorates.json[].electorateId` — confirmed **100% match, 343/343 entries, on both 2020 and 2024**
general elections, and on all 5 sampled by-elections. No `areaCode` prefix-matching needed.

**Council-name resolution, confirmed.** The join gives contest-level detail
(`electorateName`, `contestType`, `electorateType`) but not the *council* name for
division/by-election-level entries — `lgaName` is only present on top-level (mayoral) entries, and
`parentElectorateId` is `null` on by-election files entirely (a by-election's JSON has exactly one
electorate — itself — with no sibling/parent records to resolve a council name from). `eventName`
free-text parsing was tried and rejected — 15 sampled by-election names showed at least four
different phrasings (some have no year prefix, some use "Div" not "Division", some omit "Council",
Brisbane-style ward names don't match a "Council Division N" pattern at all).

The reliable approach, confirmed against all 343 entries in both 2020 and 2024, plus all 5 sampled
by-elections (**0 failures**): `electorateName` always begins with the literal council name
(`"Aurukun Shire Division 1"`, `"Brisbane City Coorparoo"` — Brisbane uses named wards, not
numbered divisions, but the council-name prefix still holds; `"Mornington Shire Division 1"` in a
by-election file with no parent record at all). So: cache QLD's 77 council names once (pulled from
any general-election file — stable, re-fetch occasionally rather than per-run) and resolve any
contest's council via **longest-matching-prefix** against that cached list. One algorithm, works
uniformly across general-election and by-election files, no dependence on `parentElectorateId` or
free text.

Party is given as a clean `declaredCandidatePartyCode` (e.g. `LNP`) — better than NSW/VIC's
free-text ballot label, no `Councils::PartyMapper` regex-matching needed for QLD; a direct code
lookup will do. `Group::NAMES` already has `qld:` branches for labor/liberals/nationals/greens
(`liberal national party (qld)` — QLD's LNP is a merged party, so `PartyMapper`'s existing
liberal/national keyword split collapses to the same group either way, which is correct for QLD).

**Party coverage, confirmed — mostly absent, and that's expected.** Checked across 2020 and 2024
(identical both years): of 285 single-winner contests (mayors + single-seat councillor by-elections),
only 26 (9%) carry a party code — the rest are declared independents, which is realistic for QLD
local government (parties rarely contest council elections outside Brisbane/major cities). Of 293
multi-winner councillor contests (candidates given as a `declaredCandidates[]` array), **0% ever
carry a party code** — the field exists on the array-item schema but QLD's data simply never
populates it there, checked across every entry in both general elections. All 5 sampled by-elections
(single-winner, using the singular field) had no party either. **Conclusion: don't treat "no
party" as a parsing gap to chase down — party is opt-in/rare in QLD's own data, not something the
join is failing to surface.**

## Design

Mirrors the existing `Councils::{Nsw,Vic}` split, minus the per-council HTTP fan-out (there's
nothing to fan out to — one file has everything):

- **`Councils::Qld::Elections`** — replaces the NSW/VIC hardcoded `ALL` array. Instead of a static
  list, fetches and filters live `elections.json` for QLD local election types. Should still cache
  the result per-run (one job, one fetch) rather than one `Elections.all` call per contest.
- **`Councils::Qld::DeclaredResultsParser`** — takes an election `stub`, fetches
  `<stub>-declared_candidates.json` + `<stub>-electorates.json`, joins on `areaCode`, and yields one
  normalised contest record per mayoral/councillor entry (council name, division name or nil,
  contest type, declared candidate(s), party code, declaration date).
- **`Councils::Qld::ImportElectionResultsJob`** — one job per election `stub` (not per council —
  there's no per-council page to fetch). Iterates the parsed contests and calls the same
  `Group::RecordRow` / `Councils::RecordCandidatePerson` / `People::RecordCouncilElectionData` /
  `Councils::PartyMapper` machinery NSW/VIC already use unchanged.
- **Top-level ingest job** — replaces `IngestElectionResultsJob`'s "discover councils, fan out
  per-council" shape with "discover election stubs from `elections.json`, fan out one
  `ImportElectionResultsJob` per stub." Spacing exists to be polite to the council results *within*
  a cycle for NSW/VIC; QLD has no equivalent per-council fetch to space out, so spacing (if any)
  only needs to cover the handful of `elections.json`-derived stub fetches, not hundreds of
  requests — likely no `IMPORT_SPACING` needed at all, or a token one.
- **No `ResultsIndexParser`/`ResultsPageParser`/`CouncillorResultsParser` equivalents needed** —
  those exist in NSW/VIC to walk from an index page down to a per-ward results page; QLD's
  `<stub>-declared_candidates.json` already is that end state for every contest at once.

### Scheduling / backfill / by-elections — one mechanism, not three

NSW/VIC needed separate Goal 1 (full ingest), Goal 2 (backfill older cycles), and Goal 3
(scheduled re-runs) phases because each cycle required its own index-page crawl. QLD doesn't: the
top-level ingest job re-reading `elections.json` and fanning out one `ImportElectionResultsJob` per
stub *is* all three at once, every run — new by-elections simply appear as new stub entries next
time `elections.json` is re-fetched. A single `sidekiq-scheduler` entry (monthly, matching NSW/VIC
cadence) should be enough from day one — no separate backfill task, no separate by-election
handling. `Group::RecordRow`/`Membership.find_or_create_by`-style idempotency (already relied on by
NSW/VIC) means re-processing already-seen stubs is safe and cheap.

## Verified against real data (2020 + 2024 general elections, 5 sampled by-elections)

All three open questions from the first draft of this plan are now resolved by pulling and
cross-checking the actual JSON (343-entry general elections for both 2020 and 2024, plus MSC24,
ICCDiv42024, Mareeba25, Balonne2025, TCCMayor2025 by-elections):

1. **Join key** — `electorateId`, not `areaCode`. 100% match, 0 failures, in every file checked.
2. **Council-name resolution** — longest-prefix match of `electorateName` against a cached list of
   QLD's 77 council names (see above). 100% resolution, 0 failures, across all 343+343 entries and
   all 5 by-elections. `parentElectorateId`-based lookup alone isn't sufficient (by-election files
   have no parent record to resolve from), and `eventName` free-text parsing isn't reliable enough
   to use (inconsistent phrasing across samples).
3. **`electorateType`/`contestType` enumeration** — fully enumerated from the 2024 general election
   (343 entries): `('Division', 'Councillor')` ×266, `('Council - Undivided', 'Mayor')` ×54,
   `('Council - Divided', 'Mayor')` ×22, `('Council - Hybrid', 'Mayor')` ×1 (Ipswich). All 77
   councils have exactly one Mayor entry each, no duplicates, no gaps. "Undivided" councils still
   expose their at-large councillor contest as a single `Division`-type entry (1 division = the
   whole council) — so **every council, divided or not, has ≥1 division-level councillor
   contest**, meaning the parser never needs an "undivided, no divisions" special case; it's always
   "iterate mayor entry + iterate division entries," uniformly.
4. **Party coverage** — confirmed real and not a parsing gap (see above): ~9% of single-winner
   contests, 0% of multi-winner councillor contests carry a party code, consistently across both
   sampled years.
5. **Historical reach** — `elections.json` only goes back to 2020 (matching NSW/VIC's own
   2021/2024 depth), so no QLD-specific historical-backfill gap beyond what NSW/VIC already accept.

No remaining open questions on data shape — this plan is ready to move from draft to implementation
whenever prioritised.
