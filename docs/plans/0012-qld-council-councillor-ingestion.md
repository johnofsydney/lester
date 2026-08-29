# QLD Council Councillor Ingestion

**Status:** Design finalised via `/grill-me` walkthrough — ready for implementation

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

Party is given both as a clean `declaredCandidatePartyCode` (e.g. `LNP`) and a free-text
`declaredCandidateParty` label (e.g. `"Liberal National Party of Queensland"`). **Decision: use the
text label, unchanged, through the existing `Councils::PartyMapper`** — its `/liberal/i`/`/national/i`
keyword regexes both already fire on QLD's label and both resolve to the same
`Group::NAMES.liberals.qld` / `.nationals.qld` group (`'liberal national party (qld)'`, since QLD's
LNP is a merged party) either way. No new code, no QLD-specific party-code mapping to build or
maintain — the code field goes unused.

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
nothing to fan out to — one file has everything), plus one extra job layer NSW/VIC don't need
(see "Job/error granularity" below).

- **`Councils::Qld::Elections`** — replaces the NSW/VIC hardcoded `ALL` array. Instead of a static
  list, fetches and filters live `elections.json` for QLD local election types
  (`Local Quadrennial`, `Local Councillor By-election`, `Local Mayoral By-election`). Cached
  per-run (one job, one fetch) rather than re-fetched per contest.
- **`Councils::Qld::KnownCouncils`** — resolves and caches the 77 QLD council names, sourced from
  the *latest* `Local Quadrennial` election's `-electorates.json` (selected by max `electionDay`
  among `electionType == 'Local Quadrennial'` entries in `elections.json` — `current` is `false`
  for both 2020 and 2024 general elections, so it can't be used to pick "latest"; this makes the
  choice self-updating when a 2028 stub appears, no code change needed). Exposes a
  longest-matching-prefix lookup: given any contest's `electorateName`, returns the council name it
  belongs to.
- **`Councils::Qld::DeclaredResultsParser`** — takes an election `stub`, fetches
  `<stub>-declared_candidates.json` + `<stub>-electorates.json`, joins on `electorateId`, resolves
  each contest's council name via `KnownCouncils`, and yields one normalised contest record per
  mayoral/councillor entry (council name, division/ward name, contest type, declared candidate(s),
  party label, declaration date).
- **`Councils::Qld::ImportElectionResultsJob`** — one job per election `stub`. Fetches + parses
  that stub's JSON (via `DeclaredResultsParser`) and fans out one
  `Councils::Qld::RecordContestResultJob` per parsed contest — it does not record anything itself.
- **`Councils::Qld::RecordContestResultJob`** — records one contest (`lock: :until_executed,
  retry: 3`, same as NSW/VIC's per-council job). Calls the same `Group::RecordRow` /
  `Councils::RecordCandidatePerson` / `People::RecordCouncilElectionData` / `Councils::PartyMapper`
  machinery NSW/VIC already use, unchanged.
- **Top-level ingest job** — replaces `IngestElectionResultsJob`'s "discover councils, fan out
  per-council" shape with "discover election stubs from `elections.json`, fan out one
  `ImportElectionResultsJob` per stub," spaced `5.seconds` apart (matching VIC's existing
  `IMPORT_SPACING`, not NSW's `90.seconds` — QLD's 45 stub fetches are lightweight JSON GETs, not
  HTML page-scrapes, but 45 near-simultaneous requests to a government API is still worth avoiding).
- **No `ResultsIndexParser`/`ResultsPageParser`/`CouncillorResultsParser` equivalents needed** —
  those exist in NSW/VIC to walk from an index page down to a per-ward results page; QLD's
  `<stub>-declared_candidates.json` already is that end state for every contest at once.

### Job/error granularity

NSW/VIC's per-council job (`lock: :until_executed, retry: 3`) means one council's parse failure
never blocks or retry-poisons the other 127. A naive QLD design — one job per stub, recording all
of that stub's contests inline — would lose this: a single malformed contest inside
`2024QLGE-declared_candidates.json` (343 contests) would raise and retry-loop the *entire* general
election, re-processing 342 already-good contests every retry until the one bad row is fixed
(idempotent, so not incorrect, but wasteful, and Sidekiq would eventually dead-letter the whole
stub over one bad row). **Decision: split fetch/parse from record** — `ImportElectionResultsJob`
does the one cheap HTTP fetch and fans out; `RecordContestResultJob` does the actual recording, one
contest at a time, so a bad contest only ever blocks itself.

### Mayors — in scope from day one

Unlike NSW/VIC, QLD mayoral contests are included in v1: recorded with title `'Mayor'` (not lumped
into `'Councillor'`) via the same `Group::RecordRow` `title:` param — no new recording machinery,
just a title distinction driven by the parsed contest's `contestType`. NSW deliberately excludes
mayoral contests today (`Councils::Nsw::ResultsPageParser` — "direct mayoral elections are out of
scope for this phase"), and VIC excludes VEC's "Leadership Team" (Lord Mayor/Deputy Lord Mayor)
contest via `EXCLUDED_CONTEST_REGEX`. That gap predates this plan and was never tracked — filed as
[johnofsydney/lester#289](https://github.com/johnofsydney/lester/issues/289) so it doesn't stay
indefinitely deferred now that QLD is setting the precedent of including mayors from day one.

### Council naming

QLD's `lgaName`/resolved council name is bare (`"Aurukun Shire"`, `"Brisbane City"`) — QLD's own
API omits the "Council" suffix that both NSW's and VIC's recorded Group names always include
(`"Albury City Council"`, `"Alpine Shire Council"`), and that matches these councils' actual
official names. **Decision: append `" Council"` when recording the Group** — restores the suffix
QLD's API happens to omit, keeps naming consistent across all three states' recorded entities.

### `council_election_data` observation shape

`People::RecordCouncilElectionData` dedups on `[state, council_slug, cycle]` — `council_slug` is
not validated as an actual URL slug, just an opaque per-council identifying string (NSW/VIC use
their source's URL slug only because that's what's available, not because the field is
semantically required to be one). **Decision:** QLD passes the *resolved council name* (from
`KnownCouncils`) as `council_slug`, and the election `stub` (e.g. `"2024QLGE"`, `"MSC24"`) as
`cycle` — stable, human-readable when eyeballing a person's stored `council_election_data`, and
unique enough given `cycle` already disambiguates elections.

### Evidence / source URL

NSW/VIC's `evidence`/`source_url` point to a per-contest results page URL — real per-contest
provenance. QLD has no per-contest URL; the finest-grained real URL is the stub's shared JSON file,
covering all of that election's contests at once. **Decision:** use the shared JSON URL as
`source_url`/`evidence`, with the specific council/division/contest-type named in the evidence text
itself (since the URL alone can't disambiguate which of up to 343 entries it refers to) — e.g.
`"Electoral Commission of Queensland 2024 Local Government election declared results for Aurukun
Shire Division 1 (councillor) (https://resultsdata.elections.qld.gov.au/2024QLGE-declared_candidates.json)"`.
Less precise than NSW's per-page link, but an honest reflection of what QLD's source actually
offers.

### Scheduling / backfill / by-elections — one mechanism, not three

NSW/VIC needed separate Goal 1 (full ingest), Goal 2 (backfill older cycles), and Goal 3
(scheduled re-runs) phases because each cycle required its own index-page crawl. QLD doesn't: the
top-level ingest job re-reading `elections.json` and fanning out one `ImportElectionResultsJob` per
stub *is* all three at once, every run — new by-elections simply appear as new stub entries next
time `elections.json` is re-fetched. A single `sidekiq-scheduler` entry (monthly, matching NSW/VIC
cadence) should be enough from day one — no separate backfill task, no separate by-election
handling. `Group::RecordRow`/`Membership.find_or_create_by`-style idempotency (already relied on by
NSW/VIC) means re-processing already-seen stubs is safe and cheap. **Decision: by-elections are in
scope for v1** — they're mechanically free (same schema, same join, same parser, no separate code
path to defer), so excluding them would only mean writing a filter to exclude now and another to
re-include later. What *is* split off into a fast-follow: wiring the `sidekiq-scheduler` cron entry
itself — ship the ingest job manually callable first, schedule it in a small separate PR, same as
NSW/VIC's own Goal 1 → Goal 3 split.

## Testing

No WebMock/VCR in this codebase's council specs — NSW/VIC parsers are tested as pure functions of
a raw fixture string (`spec/fixtures/councils/{nsw,vic}/*.html`, trimmed to a handful of councils
rather than the full page), with HTTP isolated to a separate, thin `PageDownloader` service. QLD
parsers should follow the same shape — take the raw JSON string(s), no network inside the parser.

Fixtures: trim the real ~850KB/~200KB JSON down to a small set covering every shape found during
verification — `spec/fixtures/councils/qld/`:
- an undivided-mayor council (e.g. Aurukun)
- a divided-mayor council
- the one hybrid council (Ipswich — only 1 in the state)
- a contest with a populated party (Brisbane's mayor)
- a by-election-shaped file (single electorate, no `lgaName`, no `parentElectorateId`)

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
