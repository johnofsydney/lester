# Ingest NSW State Politicians — Design

**Status:** Design only, not yet implemented. See [issue #248](https://github.com/johnofsydney/lester/issues/248) (parent spec).

## Background

There was a one-time copy/paste import of NSW politicians into the DB. It's not repeatable and its Memberships/Positions (Group = NSW Parliament) need to be destroyed before this work lands real data — mirrors the "manual pre-step" pattern from [0004](0004-ingest-federal-politicians-design.md)'s Federal Branch cleanup.

Issue #248 scopes the project to NSW and Victoria, most recent election cycles first, backfilling backwards in time. Other states out of scope. This doc covers **NSW only** — Victoria's data source (VEC) is different and needs its own design pass when picked up.

## Data source

`pastvtr.elections.nsw.gov.au` — the NSW Electoral Commission's past-results site. No API, no CSV; scrapeable HTML tables, one page per election event. Confirmed live (2026-08-23):

- **`/{event}/LA/state/elected`** (e.g. `/SG2301/LA/state/elected`) — one table, one row per electorate: `District | Candidate | Representation (party)`. This is the full statewide winners roster in a single page fetch — no need to derive winners from the per-electorate summary pages.
- **`/{event}/LA/{electorate}/cc/fp_summary`** (e.g. `/SG2301/LA/auburn/cc/fp_summary`) — first-preference results table for one electorate: every candidate (winner and unsuccessful) with their declared party.
- Same shape exists under `/LC/` for the Legislative Council — not yet confirmed live, needs a check when LC ingestion is built (LC is proportional/multi-member, so the `elected`-equivalent page may differ in structure).

Other candidates considered and rejected:
- `elections.nsw.gov.au` main site and `data.nsw.gov.au` — checked; the open datasets there are depersonalised voting-transaction logs (postal/pre-poll/iVote), not candidate/party/result rosters. Not useful for this.
- Guessed direct XLSX candidate-list URLs (`SGE2023 LA Candidates.xlsx`) — 404'd. Not pursued further since the HTML tables above already cover the need.

`SG2301` is the 2023 NSW state general election's event code on pastvtr; each election cycle has its own code, discovered per-cycle (not yet inventoried — needed before backfill can proceed past the most recent election).

## Reuse: this is a sibling of the NSW local council ingestion, not a fresh problem

The `Councils::*` namespace (shipped, see [0002](0002-local-council-councillor-ingestion.md)) already solves this exact class of problem — same `pastvtr.elections.nsw.gov.au` host, same "scrape a results page, resolve party, resolve person, no per-candidate ID available" shape — for NSW council elections. **Decided: build on that infrastructure rather than a parallel design.** Concretely:

- **`Councils::PageDownloader`** — reuse as-is for fetching `elected`/`fp_summary` pages (Faraday + browser User-Agent header + timeout, returns `nil` on failure rather than raising).
- **`Councils::PartyMapper`** — reuse/extend, not `MapGroupNamesAecRecipients` (an earlier draft of this doc proposed the AEC mapper; superseded). `PartyMapper` already does exactly what "unsuccessful candidate only if their party already exists as a Group" needs: keyword-match a party label to a `Group::NAMES` family, then a real `Group.find_by_name_i` lookup, returning `nil` (i.e. "don't ingest") if that Group doesn't exist. It's narrower than the AEC mapper (4 major families only: Labor/Liberal/National/Greens, no minor-party aliases) but it's the actual precedent for *this* problem, and it already performs the DB-existence check natively rather than needing a separate step bolted on.
- **`Councils::RecordCandidatePerson`** — generalize in place rather than fork. Confirmed both `Councils::Nsw::ImportCouncilResultRowJob` and `Councils::Vic::ImportCouncilResultRowJob` already call the same class (`Councils::RecordCandidatePerson.call(name:, council:)`) — there's no separate VIC copy to reconcile, one service already serves both state council pipelines. Its `existing_council_member` method is really "person with a Membership in this scope Group," with nothing council-specific beyond the `council:` param name and `council.id` in the query — rename the param to `scope_group:`, move it up a namespace level out of `Councils::` (it'll have three callers once NSW state politicians lands: NSW council, VIC council, NSW state politicians), and have all three call sites pass their own scope Group (a specific council, or NSW Parliament).
- **`Councils::Nsw::Elections`** — the answer to "how are election event codes enumerated": a hardcoded, oldest-first array (`{ id:, year:, election_date: }`) with `.find`/`.latest`. State elections need their own equivalent module (different event-code format — `SG2301` vs `LG2101` — and a different, currently unconfirmed set of cycles), but the *pattern* (hardcoded array, not live-discovered) carries over directly, including its documented caveat that older cycles may live under a structurally different legacy site path.

**Bug found while reviewing `PartyMapper` for reuse, must be fixed as part of this work, not carried over:** `KEYWORDS_TO_NAMES_KEY` maps `/liberal/i => :liberals`. `"Liberal Democratic Party".match?(/liberal/i)` is `true` — so as written today, `PartyMapper` would misclassify LDP (one of the three real examples confirmed for this project) into the actual Liberal Party's Group. Needs a negative-lookahead or an explicit LDP exclusion before this mapper is trusted for state-election party strings, which include LDP candidates where council ballots may not have.

## Who gets ingested

1. **Every winning candidate**, regardless of party — sourced from the `elected` page. Always creates their party Group if it doesn't already exist (winners aren't gated on existing-Group; only losers are).
2. **Unsuccessful candidates, but only if `PartyMapper` resolves their declared party to an existing Group** — sourced from each electorate's `fp_summary` page. This naturally excludes independents (no party to resolve) and micro-parties (no matching `Group::NAMES` family, or a family match with no existing Group row) without maintaining a separate whitelist anywhere. Confirmed real examples: The Greens NSW, Liberal Democratic Party (once the bug above is fixed), and The Liberal Party of Australia (NSW Division) would be included; a one-off micro-party like "Sustainable Australia Party - Stop Overdevelopment / Corruption" would be excluded.

Expect `PartyMapper`'s 4-family keyword coverage to need extending for state-specific party strings not seen in council data — extend its table in place rather than forking a parallel mapper, same reasoning as for the LDP bug fix above.

## Disambiguation

pastvtr exposes no per-candidate identifier at all — confirmed by `Councils::RecordCandidatePerson`'s own comment, which hit this identically for council elections. **Decided: follow `Councils::RecordCandidatePerson`'s pattern** — see [ADR 0007](../adr/0007-mass-ingestion-disambiguation-scoped-not-global.md), which generalizes the rule this design applies: reuse an existing Person only if they already have a Membership scoped to the specific thing being ingested into (there: the specific council; here: NSW Parliament, the returning-member case) — never a bare global `Person.find_by(name:)` lookup, which the AEC/ACNC/OpenAustralia-oriented `People::RecordPerson#call` falls back to and which the code's own comment already flags as fragile at that scope.

Confirmed live sample from the `elected` page: `DAVIES Tanya` — surname first, all-caps, space-separated (not comma-separated). `People::RecordPerson.clean_name` handles comma-separated `"Last, First"` but has no surname-first swap for this shape, and `Councils::RecordCandidatePerson` already calls `People::RecordPerson.clean_name` too, so it presumably has the same gap against council data — worth checking whether council ingestion already special-cased this somewhere before assuming it needs solving fresh here. **Decided:** whatever the reformatting step turns out to be, it's parsed locally (new service, or a shared helper alongside `Councils::RecordCandidatePerson`'s equivalent if one already exists), not added to shared `People::RecordPerson.clean_name` — that method already carries several other sources' accreted, source-specific hacks, and this shouldn't become another one's baggage.

## What gets recorded

**Decided: follow the council precedent exactly, per [ADR 0006](../adr/0006-council-membership-position-dates-deferred-to-interpretation.md) — Ingest creates the Membership immediately, but never with dates.** This was not an easy call for councils: a staging spot-check found dates that "didn't feel right" (a councillor re-elected in 2024 who also won in 2021 might have first been elected in 2016 or earlier — a cycle the pipeline may never reach — so `start_date: <most recent declared-elected date>` looks precise but overstates what's actually known), which is why ADR 0006 exists at all. Applying that here rather than re-deriving it fresh:

For every ingested person (winner, or unsuccessful candidate whose party already has a Group in the DB):
- The `Person` record, via the generalized `RecordCandidatePerson` (see above), scoped to the NSW Parliament Group.
- **A `Membership` (and `Position`, e.g. `title: 'Member of the Legislative Assembly'`) linking them to the NSW Parliament Group itself — created immediately, permanently undated**, via `Group::RecordRow`, mirroring `Councils::{Nsw,Vic}::ImportCouncilResultRowJob`'s `Group::RecordRow.new(group: council, person:, title: 'Councillor', evidence:).call`. This is required, not optional — issue #248 and the project owner are explicit that this process must create the Parliament Membership, not just stage raw data for a future step to create it from scratch.
- If they have a party, a `Membership` linking them to that party's Group (find-or-create for winners; already guaranteed to exist for ingested losers) — also undated, same reasoning.
- A dated raw observation appended to a new `Person#state_election_data` jsonb column (mirroring `Person#council_election_data` / `People::RecordCouncilElectionData` — append-only, deduped by a key tuple such as `(state, event_id, electorate, house)`, not overwrite-on-fetch, since pastvtr data arrives piecemeal — one import run per electorate/cycle — the same way council data does, not in one full-history shot the way OpenAustralia's does (ADR 0001 vs ADR 0006 is the same fork; this follows ADR 0006's side of it).

**No `close_departed_members`-equivalent, no end-dating, no continuity/backfill-order logic** — ADR 0006 removed all of that for councils for the same reason it doesn't belong here: without dates, there's no confidence to act on "this person left." A former MP's Membership just stays open (undated) until a real interpretation pass exists — an accepted, explicit trade-off (the graph over-shows current members until then), not an oversight. This also means, per ADR 0006's "Consequence: run order no longer matters" section, that NSW state politician backfill and current-cycle ingestion should end up order-independent the same way councils are — worth confirming once implemented, not assumed here.

**Interpretation itself (a future `Interpretation::RecordMembershipsAndPositions`-style pass deriving real start/end dates from `state_election_data`, mirroring the still-not-built council equivalent) is out of scope for this ticket**, per issue #248 — this doc only commits to the raw data existing in a shape that pass can consume later.

## Not yet designed

- Legislative Council ingestion (multi-member proportional — the `elected`/`fp_summary` page shapes need separate confirmation).
- The state-election equivalent of `Councils::Nsw::Elections` — actual event codes and dates for past NSW state election cycles beyond `SG2301` (2023), needed before backfill can proceed past the most recent election.
- The manual pre-step to destroy the legacy one-time-import Memberships/Positions (needs the actual Group id for NSW Parliament, analogous to [0004](0004-ingest-federal-politicians-design.md)'s `Group.find(877)` for Federal Parliament).
- Victoria (VEC) state election ingestion itself — separate source, separate design pass. (Note: this is distinct from the VIC *council* pipeline referenced above, which already exists and already shares `RecordCandidatePerson`.)
