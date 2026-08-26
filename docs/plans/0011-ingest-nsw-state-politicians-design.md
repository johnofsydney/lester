# Ingest NSW State Politicians — Design

**Status:** Design only, not yet implemented. See [issue #248](https://github.com/johnofsydney/lester/issues/248) (parent spec).

## Background

**One `Group` for the whole of NSW Parliament, not one per house.** Mirrors [0004](0004-ingest-federal-politicians-design.md)'s federal precedent — `Group.federal_parliament` is a single Group covering both the House and Senate, with a `Position` (`title:`) distinguishing which house a given Membership represents, not separate Groups. Same here: LA and LC members both get a Membership in `Group.nsw_parliament`; `title:` (e.g. `'Member of the Legislative Assembly'` vs `'Member of the Legislative Council'`) is what distinguishes them.

There was a one-time copy/paste import of NSW politicians into the DB — confirmed locally as id 3740 ("nsw parliament"), currently holding 512 Memberships, no dates, no evidence. It's not repeatable and needs to be destroyed before this work lands real data — mirrors the "manual pre-step" pattern from [0004](0004-ingest-federal-politicians-design.md)'s Federal Branch cleanup, with one addition: unlike the federal cleanup (which only ever deleted Memberships/Positions, never People), this cleanup also deletes any Person left with zero Memberships once the legacy ones are removed — see [the cleanup runbook](../runbooks/nsw-state-politicians-legacy-cleanup.md) for the full reasoning and sketch.

**Decided (2026-08-27): `Group.nsw_parliament` is a name lookup (`Group.find_by(name: 'nsw parliament')`), not a hardcoded id, deliberately deviating from this project's usual hardcoded-ID-over-name-lookup convention.** Unlike `Group.federal_parliament`'s `Group.find(877)` — a long-established production id — this Group's id is only known from local/dev observation (3740) and isn't guaranteed to be the same when this ships to production. A name lookup is the correct choice specifically because the id isn't yet a known, stable production fact; once it is (post-deploy), a future ADR could revisit hardcoding it, but there's no need to force that now.

Issue #248 scopes the project to NSW and Victoria, most recent election cycles first, backfilling backwards in time. Other states out of scope. This doc covers **NSW only** — Victoria's data source (VEC) is different and needs its own design pass when picked up.

## Data source

`pastvtr.elections.nsw.gov.au` — the NSW Electoral Commission's past-results site. No API, no CSV; scrapeable HTML tables, one page per election event. Confirmed live (2026-08-23):

- **`/{event}/LA/state/elected`** (e.g. `/SG2301/LA/state/elected`) — one table, one row per electorate: `District | Candidate | Representation (party)`. This is the full statewide winners roster in a single page fetch — no need to derive winners from the per-electorate summary pages.
- **`/{event}/LA/{electorate}/cc/fp_summary`** (e.g. `/SG2301/LA/auburn/cc/fp_summary`) — first-preference results table for one electorate: every candidate (winner and unsuccessful) with their declared party.

**LC (Legislative Council) confirmed live — structurally different from LA, not a same-shape sibling:**
- There is **no** `/LC/state/elected` page (404) — LC is a proportional, multi-member, group-ticket system, so "winners per electorate" doesn't apply. The actual winners page is **`/{event}/LC/state/candidates_elected`** (found via the `/LC/results` hub page's links, not guessable from the LA pattern) — one row per elected member: `Candidate Name | Group letter | Group Name | Elected at Count`. Confirmed live for `SG2301`: 21 rows. Party is given as a short ballot label (`LABOR`, `THE GREENS`, `ONE NATION`, `LIBERAL / THE NATIONALS` for a joint ticket) — visibly different formatting from the LA `elected` page's full legal party names, so `PartyMapper`'s keyword-matching needs verifying against this format specifically, not assumed to transfer from LA tuning.
- `/{event}/LC/state/cc/fp_summary` **does** exist (200, confirmed) but is a first-preference-by-group-ticket table (candidates nested under ballot Group letters, quota fractions, not a flat per-candidate table like LA's) — using it for "unsuccessful LC candidates whose party already has a Group" needs its own parser, not a reuse of whatever parses LA's `fp_summary`.
- LC ingestion is still not designed beyond this — the pages exist and are confirmed, but "who counts as an unsuccessful-but-worth-ingesting LC candidate" under a quota system is a different question than LA's simple win/lose, not yet thought through.

Other candidates considered and rejected:
- `elections.nsw.gov.au` main site and `data.nsw.gov.au` — checked; the open datasets there are depersonalised voting-transaction logs (postal/pre-poll/iVote), not candidate/party/result rosters. Not useful for this.
- Guessed direct XLSX candidate-list URLs (`SGE2023 LA Candidates.xlsx`) — 404'd. Not pursued further since the HTML tables above already cover the need.

**Election event codes confirmed** via `elections.nsw.gov.au/elections/past-results/state-election-results`'s per-year pages, which each link their pastvtr event code: `SG2301` (2023), `SG1901` (2019) — both confirmed live on the current `LA/state/elected` and `LC/state/candidates_elected` page shapes above. **2015 and earlier live under a structurally different legacy path** (`pastvtr.elections.nsw.gov.au/SGE2015/home.htm`, `SGE2011/Vtrhome.htm` — old `SGE{year}` naming, not `SG{yy}{seq}`) — same "legacy site, different structure" situation `Councils::Nsw::Elections`' own comment already documents for council data pre-2016. Backfill past 2019 needs a second parser for that legacy shape, not assumed to be a drop-in.

## Reuse: this is a sibling of the NSW local council ingestion, not a fresh problem

The `Councils::*` namespace (shipped, see [0002](0002-local-council-councillor-ingestion.md)) already solves this exact class of problem — same `pastvtr.elections.nsw.gov.au` host, same "scrape a results page, resolve party, resolve person, no per-candidate ID available" shape — for NSW council elections. **Decided: build on that infrastructure rather than a parallel design.** Concretely:

- **`Councils::PageDownloader`** — reuse as-is for fetching `elected`/`fp_summary` pages (Faraday + browser User-Agent header + timeout, returns `nil` on failure rather than raising).
- **`Councils::PartyMapper`** — reuse/extend, not `MapGroupNamesAecRecipients` (an earlier draft of this doc proposed the AEC mapper; superseded). `PartyMapper` already does exactly what "unsuccessful candidate only if their party already exists as a Group" needs: keyword-match a party label to a `Group::NAMES` family, then a real `Group.find_by_name_i` lookup, returning `nil` (i.e. "don't ingest") if that Group doesn't exist. It's narrower than the AEC mapper (4 major families only: Labor/Liberal/National/Greens, no minor-party aliases) but it's the actual precedent for *this* problem, and it already performs the DB-existence check natively rather than needing a separate step bolted on.
- **`Councils::RecordCandidatePerson`** — generalize in place rather than fork. Confirmed both `Councils::Nsw::ImportCouncilResultRowJob` and `Councils::Vic::ImportCouncilResultRowJob` already call the same class (`Councils::RecordCandidatePerson.call(name:, council:)`) — there's no separate VIC copy to reconcile, one service already serves both state council pipelines. Its `existing_council_member` method is really "person with a Membership in this scope Group," with nothing council-specific beyond the `council:` param name and `council.id` in the query — rename the param to `scope_group:`, move it up a namespace level out of `Councils::` (it'll have three callers once NSW state politicians lands: NSW council, VIC council, NSW state politicians), and have all three call sites pass their own scope Group (a specific council, or NSW Parliament).
- **`Councils::Nsw::Elections`** — the answer to "how are election event codes enumerated": a hardcoded, oldest-first array (`{ id:, year:, election_date: }`) with `.find`/`.latest`. State elections need their own equivalent module (different event-code format — `SG2301` vs `LG2101` — and a different, currently unconfirmed set of cycles), but the *pattern* (hardcoded array, not live-discovered) carries over directly, including its documented caveat that older cycles may live under a structurally different legacy site path.

**Bug found while reviewing `PartyMapper` for reuse, must be fixed as part of this work, not carried over:** `KEYWORDS_TO_NAMES_KEY` maps `/liberal/i => :liberals`. `"Liberal Democratic Party".match?(/liberal/i)` is `true` — so as written today, `PartyMapper` would misclassify LDP (one of the three real examples confirmed for this project) into the actual Liberal Party's Group. Needs a negative-lookahead or an explicit LDP exclusion before this mapper is trusted for state-election party strings, which include LDP candidates where council ballots may not have.

## Who gets ingested

Same rule for both houses — **decided:** LC uses the identical existing-party-Group gate as LA, just read off LC's own pages, not a quota-specific rule (e.g. not "only those within N quotas of winning").

1. **Every winning candidate**, regardless of party — LA from the `elected` page, LC from `candidates_elected`. Always creates their party Group if it doesn't already exist (winners aren't gated on existing-Group; only losers are).
2. **Unsuccessful candidates, but only if `PartyMapper` resolves their declared party to an existing Group** — LA from each electorate's `fp_summary` page; LC from `/LC/state/cc/fp_summary`'s group-ticket table (needs its own parser — see LC section above — but the same gate once a candidate row is extracted from it). This naturally excludes independents (no party to resolve) and micro-parties (no matching `Group::NAMES` family, or a family match with no existing Group row) without maintaining a separate whitelist anywhere. Confirmed real examples: The Greens NSW, Liberal Democratic Party (once the bug above is fixed), and The Liberal Party of Australia (NSW Division) would be included; a one-off micro-party like "Sustainable Australia Party - Stop Overdevelopment / Corruption" would be excluded.

Expect `PartyMapper`'s 4-family keyword coverage to need extending for state-specific party strings not seen in council data — extend its table in place rather than forking a parallel mapper, same reasoning as for the LDP bug fix above. LC's short ballot-label format (`LABOR`, `THE GREENS`, joint tickets like `LIBERAL / THE NATIONALS`) is a second format `PartyMapper` needs to handle correctly alongside LA's full legal names.

**Decided: joint-ticket labels resolve to whichever family is named first.** `LIBERAL / THE NATIONALS` → Liberals (single Membership, not two, not "unresolvable"). General rule for any other joint-ticket string this or future elections surface: always take the first-named party as the group — don't special-case Liberal/Nationals specifically in `PartyMapper`, implement the "first match wins" ordering generically (e.g. check the string up to the first `/` before falling through to the rest) so it holds for tickets not yet seen.

## Disambiguation

pastvtr exposes no per-candidate identifier at all — confirmed by `Councils::RecordCandidatePerson`'s own comment, which hit this identically for council elections. **Decided: follow `Councils::RecordCandidatePerson`'s pattern** — see [ADR 0010](../adr/0010-mass-ingestion-disambiguation-scoped-not-global.md), which generalizes the rule this design applies: reuse an existing Person only if they already have a Membership scoped to the specific thing being ingested into (there: the specific council; here: NSW Parliament, the returning-member case) — never a bare global `Person.find_by(name:)` lookup, which the AEC/ACNC/OpenAustralia-oriented `People::RecordPerson#call` falls back to and which the code's own comment already flags as fragile at that scope.

Confirmed live sample from the `elected` page: `DAVIES Tanya` — surname first, all-caps, space-separated (not comma-separated). `People::RecordPerson.clean_name` handles comma-separated `"Last, First"` but has no surname-first swap for this shape, and `Councils::RecordCandidatePerson` already calls `People::RecordPerson.clean_name` too, so it presumably has the same gap against council data — worth checking whether council ingestion already special-cased this somewhere before assuming it needs solving fresh here. **Decided:** whatever the reformatting step turns out to be, it's parsed locally (new service, or a shared helper alongside `Councils::RecordCandidatePerson`'s equivalent if one already exists), not added to shared `People::RecordPerson.clean_name` — that method already carries several other sources' accreted, source-specific hacks, and this shouldn't become another one's baggage.

## What gets recorded

**Decided: follow the council precedent exactly, per [ADR 0006](../adr/0006-council-membership-position-dates-deferred-to-interpretation.md) — Ingest creates the Membership immediately, but never with dates.** This was not an easy call for councils: a staging spot-check found dates that "didn't feel right" (a councillor re-elected in 2024 who also won in 2021 might have first been elected in 2016 or earlier — a cycle the pipeline may never reach — so `start_date: <most recent declared-elected date>` looks precise but overstates what's actually known), which is why ADR 0006 exists at all. Applying that here rather than re-deriving it fresh:

**Correction (found during local spot-checking, 2026-08-26): the NSW Parliament Membership is winner-only, not "every ingested person."** An unsuccessful-but-ingested candidate never sat in Parliament — giving them a `Group.nsw_parliament` Membership was a real bug in this doc's original wording (and in the first implementation, which followed it literally: e.g. Adam Guise, who lost Lismore to Janelle Saffin, ended up showing as a sitting MLA). Corrected below.

For every ingested person:
- The `Person` record, via the generalized `RecordCandidatePerson` (see above), scoped to the NSW Parliament Group.
- **If (and only if) they won: a `Membership` (and `Position`, `title: 'Member of the Legislative Assembly'` or `'Member of the Legislative Council'` depending on house) linking them to the single NSW Parliament Group (`Group.nsw_parliament`) — created immediately, permanently undated**, via `Group::RecordRow`, mirroring `Councils::{Nsw,Vic}::ImportCouncilResultRowJob`'s `Group::RecordRow.new(group: council, person:, title: 'Councillor', evidence:).call`. This is required for winners, not optional — issue #248 and the project owner are explicit that this process must create the Parliament Membership, not just stage raw data for a future step to create it from scratch. An ingested *unsuccessful* candidate gets no Parliament Membership at all.
- If they have a party, a `Membership` linking them to that party's Group (find-or-create for winners; already guaranteed to exist for ingested losers) — also undated, same reasoning. **The party Group must be looked up/created without constraining by `type` — every real party Group in this app is a plain Group (`type: nil`), not a Tag** (Tags are category labels like Charities/Lobbyists, not political parties). The first implementation constrained the winner-path lookup to `type: 'Tag'`, which silently created duplicate Groups instead of finding the real ones (confirmed: 4 duplicate Tag-typed party Groups, 84 memberships wrongly attached to them, invisible in the person-page UI) — fixed by using the same type-agnostic `find_by_name_i` lookup the loser path (`Councils::PartyMapper`) already used correctly.
- A dated raw observation appended to a new `Person#state_election_data` jsonb column (mirroring `Person#council_election_data` / `People::RecordCouncilElectionData` — append-only, deduped by a key tuple such as `(state, event_id, electorate, house)`, not overwrite-on-fetch, since pastvtr data arrives piecemeal — one import run per electorate/cycle — the same way council data does, not in one full-history shot the way OpenAustralia's does (ADR 0001 vs ADR 0006 is the same fork; this follows ADR 0006's side of it). This is recorded for both winners and ingested losers, regardless of the Parliament Membership distinction above.

**No `close_departed_members`-equivalent, no end-dating, no continuity/backfill-order logic** — ADR 0006 removed all of that for councils for the same reason it doesn't belong here: without dates, there's no confidence to act on "this person left." A former MP's Membership just stays open (undated) until a real interpretation pass exists — an accepted, explicit trade-off (the graph over-shows current members until then), not an oversight. This also means, per ADR 0006's "Consequence: run order no longer matters" section, that NSW state politician backfill and current-cycle ingestion should end up order-independent the same way councils are — worth confirming once implemented, not assumed here.

**Interpretation itself (a future `Interpretation::RecordMembershipsAndPositions`-style pass deriving real start/end dates from `state_election_data`, mirroring the still-not-built council equivalent) is out of scope for this ticket**, per issue #248 — this doc only commits to the raw data existing in a shape that pass can consume later.

## Election cycles (`NswStatePoliticians::Elections`-equivalent)

Confirmed live, mirroring `Councils::Nsw::Elections`' shape:

```ruby
module NswStatePoliticians::Elections
  ALL = [
    { id: 'SG1901', year: 2019 },
    { id: 'SG2301', year: 2023 }
  ].freeze
  # 2015 and earlier live under a structurally different legacy path
  # (pastvtr.elections.nsw.gov.au/SGE{year}/...) -- not covered here, see docs/plans/0011.

  def self.find(event_id) = ALL.find { |e| e[:id] == event_id } || raise(ArgumentError, "Unknown NSW state election_id: #{event_id}")
  def self.latest = ALL.last
end
```

Both confirmed live on the current page structure (`LA/state/elected`, `LC/state/candidates_elected`). By-elections (e.g. the 2024 Epping/Hornsby/Pittwater, 2025 Kiama/Port Macquarie ones listed on `elections.nsw.gov.au`) are **not covered by this list** — they're single-electorate events with their own separate result pages, not part of a general-election `SG*` sweep; whether/how to fold by-election winners into this ingestion (they're real MPs, but discovered a different way) is not designed here.

## Not yet designed

- LC's `fp_summary` group-ticket parser, and how `PartyMapper` should resolve joint-ticket labels like `LIBERAL / THE NATIONALS` (which family, or both, or neither) — the *rule* for who's ingested is decided (same existing-Group gate as LA), but extracting a clean candidate+party row from LC's page shape isn't.
- By-election handling (see above) — separate discovery mechanism from the general-election sweep.
- The legacy pre-2019 (`SGE2015` and earlier) page structure — different enough from the current `SG*` shape that it needs its own parser before backfill can reach it, not assumed to be a drop-in. Tracked separately, deliberately not blocking this doc's initial implementation: [issue #290](https://github.com/johnofsydney/lester/issues/290).
- The manual pre-step to destroy the legacy one-time-import Memberships/Positions/orphaned People — `Group.nsw_parliament` confirmed locally (id 3740, not hardcoded — see above), full design and rake-task sketch in [the cleanup runbook](../runbooks/nsw-state-politicians-legacy-cleanup.md); not yet implemented, and worth reconciling the runbook's "expected ~93 electorates but found 512 memberships" gap before running it for real.
- Victoria (VEC) state election ingestion itself — separate source, separate design pass. (Note: this is distinct from the VIC *council* pipeline referenced above, which already exists and already shares `RecordCandidatePerson`.)
