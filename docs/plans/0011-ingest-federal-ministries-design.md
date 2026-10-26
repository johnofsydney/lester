# Ingest Federal Ministries — Design & Roadmap

**Status:** Sketch — not yet started, not yet grilled in full

## Why this exists, and why it's not an extension of Increment 4

`docs/plans/0004-ingest-federal-politicians-design.md`'s "Later — Ministries and Cabinet
offices" section assumed OpenAustralia's `office` field on each Term was a usable historical
record of ministerial appointments, needing only an Interpretation step against data already
ingested. Checked against real production data and found false on two counts:

- **Not historical.** Anthony Albanese (`person_id: 10007`) has exactly one `office` entry — his
  current PM role (2022–present). Nothing from his 2007–2013 ministerial career (Infrastructure
  and Transport, Deputy PM) under Rudd/Gillard is present.
- **Not even a reliable current snapshot.** Peter Dutton — Defence Minister, Home Affairs
  Minister, and Leader of the Opposition for years — has **zero** `office` entries at all, not
  even a "most recent" one.

Whole-database check: 59 people have any `office` entry at all, 123 entries total, mixing
ministerial, shadow-ministerial, and internal party-leadership roles (Leader of the Opposition,
Manager of Opposition Business, committee chairs) with no way to distinguish them structurally.
Not usable as-is for either a historical record or a live snapshot.

This plan supersedes that section of 0004. It does not touch Increments 1–4 or the existing
Parliament/party pipeline — OpenAustralia remains the source of truth for Person identity,
Parliament Membership, and party affiliation, unchanged.

## Chosen data source: Wikidata

See `docs/backlog/ministerial-history-data-source.md` for the full comparison (Wikidata,
Wikipedia, APH Handbook, data.gov.au, They Vote For You). Summary: Wikidata models each
politician's career as `P39` ("position held") statements with `P580`/`P582` (start/end date)
qualifiers, pointing at typed position entities (e.g. "Minister for Defence (Australia)").
Verified live via direct SPARQL query — recovers exactly the gaps above (Albanese's full
2007–2013 ministerial career, all of Dutton's Home Affairs/Defence/Opposition Leader positions).
CC0 licensed, actively maintained.

Confirmed via direct property search against Wikidata's own API
(`wbsearchentities?search=OpenAustralia&type=property`, empty result set): **Wikidata does not
cross-reference OpenAustralia's `person_id`**. No shortcut available — matching Person ↔
Wikidata QID has to be built from scratch, it's not a free join.

## Two-phase structure

Kept as two independent phases because Phase 2 (ministerial Interpretation) is blocked on
Phase 1 (QID matching) existing for a person, but Phase 1 has value and can be verified on its
own before any ministry-specific modeling is designed in detail.

---

## Phase 1 — Assign a Wikidata QID to every Person with an OpenAustralia ID

Goal: for every `Person` with an `open_australia` `external_identifiers` row (i.e. everyone the
existing pipeline has already ingested — current politicians plus, once Increment 4 ships, the
50-year historical set), find and store their Wikidata QID as a new `external_identifiers` row,
`source: 'wikidata'`.

This is enrichment against existing People, mirroring how `aec`/`acnc` identifiers are attached
today — not a new entity-creation path, no new People should be created by this phase.

Design settled via a `grill-me` pass (2026-08-23). Decisions below; see git history of this file
for the raw Q&A if the reasoning behind any of them needs revisiting.

### Bulk pull, not per-person lookups

Fetch once, in bulk, rather than one Wikidata call per Person. Reasons: a single round-trip
instead of thousands; gives a complete candidate set to spot name collisions across up front
rather than discovering them one query at a time; and — the deciding factor — it decouples
*fetching* from *matching*. Matching logic will very likely need iteration (see below); with a
local copy of the raw pull, iterating on matching costs nothing further against Wikidata.

**Query shape:** try one unchunked SPARQL query first (`?person wdt:P39 ?position .
?position wdt:P279* wd:Q21032693` or similar "member of the Parliament of Australia" subclass
check, pulling name + all P39 statement qualifiers). Don't pre-build pagination/chunking against
a timeout that hasn't been observed — fall back to a chunked pull (e.g. per-decade) only if the
single query actually fails against the live endpoint.

### Staging table: `wikidata_entities`

```ruby
create_table :wikidata_entities do |t|
  t.string :qid, null: false, index: { unique: true }
  t.string :name, null: false
  t.jsonb :raw_data, null: false, default: {}   # full P39 statements + whatever else was pulled
  t.references :person, foreign_key: true, null: true   # filled in once matched
  t.boolean :dismissed, default: false, null: false     # "none of these" from the review UI
  t.timestamps
end
```

Named generically (`wikidata_entities`, not `wikidata_politicians`) and shaped to hold any
Wikidata entity, even though Phase 1 only populates and matches federal politicians. This is
deliberate: a general Person↔Wikidata matcher (matching charity board members, lobbyists, or
anyone else in the DB who has a Wikidata entry, not just politicians) is a known likely future
need, and this table plus the review UI below are being built as reusable machinery for that,
not single-purpose. The *narrow* part of this phase is which rows get populated and which
matching query runs — not the schema or the UI.

**Data lifecycle:** this table is working/staging state, not a new permanent store alongside
`external_identifiers`. Once a row is matched (its `person_id` set and the corresponding
`external_identifiers` row created) and any data Phase 2 needs has been copied out into real
`Membership`/`Position` records, the row has done its job and its `raw_data` should not be
treated as a long-term source of truth — `people.open_australia_data`-style, the real record
lives on the Person/Membership/Position side. The table itself stays in the schema (not
dropped after this project ships) specifically so a future bulk-match run — a different
Wikidata query, a different target dataset — can reuse it rather than re-migrating it back into
existence.

### Matching algorithm

1. Exact normalised-name match, exactly one Wikidata candidate → auto-accept: set `person_id` on
   the `wikidata_entities` row and create the `external_identifiers` row (`source: 'wikidata'`)
   immediately.
2. Exact normalised-name match, multiple candidates → do not guess; surface in the review UI
   below.
3. No exact name match (nicknames, middle names, spelling drift) → leave unmatched. No fuzzy
   string matching in this phase — mirrors `docs/plans/0006-person-disambiguation-design.md`'s
   own conclusion that name-only matching is unreliable without it.
4. Full coverage is not required to ship Phase 2 — some well-matched people is enough to be
   useful; unmatched People simply have no ministerial data yet, revisited later.

**Verification of auto-accepted (unambiguous) matches:** no per-match review — a one-time
spot-check of a sample (~20-30) after the first real bulk run, to sanity-check the approach
before trusting the full set. Same validation pattern as Increment 4's backfill (real run on
staging first, watch what happens). Not a permanent process or extra schema.

### Review UI for ambiguous matches

One ActiveAdmin custom page (like `Admin::People::ExplodePerson` — not a full CRUD resource),
named generically (e.g. `Admin::People::MatchWikidataCandidate`) since the UI itself doesn't
encode "politician" anywhere and Phase 3 should be able to reuse it unchanged.

On every page load, re-queries live rather than maintaining a separate "pending matches" table:
for each Person with an `open_australia` id and no `wikidata` `external_identifiers` row yet,
find all name-matching, non-`dismissed` `wikidata_entities` rows; list only the Ambiguous cases
(≥2 candidates). For each, show the candidates side by side (name, dates, electorate — whatever
disambiguating fields were pulled) with a per-candidate action:

- **"This one"** → sets `person_id` on that `wikidata_entities` row, creates the
  `external_identifiers` row. Person drops out of the list on next load (the query's "no
  identifier yet" condition no longer matches).
- **"None of these"** → sets `dismissed: true` on the candidate rows for that Person, so they
  stop resurfacing without needing a separate persisted workflow/state machine.

## Phase 2 — Ministerial Ingest & Interpretation

Once a Person has a `wikidata` external identifier, follows the same Ingest/Interpretation split
as the existing OpenAustralia pipeline:

- **Ingest**: fetch raw `P39` statements (position QID, `P580`/`P582` dates) for a person's QID,
  store unmodified — new jsonb column on `people` (e.g. `wikidata_data` +
  `wikidata_data_fetched_at`), same overwrite-not-log semantics as ADR-0001.
- **Interpretation**: map the ~30–50 distinct "Minister for X (Australia)"-shaped position
  entities to internal Department `Group`s (find-or-create, likely tagged under the existing
  unused `Group.government_department_tag`, id 124514), create/close `Membership` + `Position`
  records per person per portfolio.

### Open questions for this phase (not yet resolved — out of scope until Phase 1 ships)

- **Which Wikidata positions count.** P39 covers a person's entire life — MP, minister, party
  leader, non-political roles (e.g. prior career). Needs a filter (likely a curated list or a
  Wikidata subclass check) to select only ministerial/shadow-ministerial positions, and a
  decision on whether shadow ministry and internal party roles (deputy leader, whip) are in
  scope for this phase or deliberately excluded.
- **Open-ended terms.** How to treat a P39 entry with no `P582` (no end date) — same "still
  ongoing" semantics as OpenAustralia's `"9999-12-31"` sentinel, or does absence mean something
  different in Wikidata's data model (worth checking, don't assume the same convention).
- **Reshuffles / multiple stints in the same portfolio.** Albanese's Infrastructure and
  Transport portfolio has two separate P39 entries either side of a 2013 gap — needs the same
  kind of "don't silently merge distinct stints" care that ADR-0003's Office Holder handling and
  the original abandoned bulk-import bug (`group_into_stints`) both had to solve for.
- **Ministry (collective cabinet) grouping.** "Albanese Ministry", "Turnbull Ministry" as a
  named collective is a separate concept from per-portfolio Membership, not directly given by a
  single P39 statement — likely needs its own resolution (possibly from the same Wikidata data,
  since Wikidata also models the ministry-as-entity; not yet checked) and should stay a distinct
  design decision, not conflated with the per-portfolio work above. Same caution 0004 already
  flagged for this sub-problem.
- **New ADRs.** Expect at least one, likely two, covering the position-entity→Group mapping
  rule and the open-ended/reshuffle handling — same pattern as ADR-0002/0003/0005 for the
  parliamentary pipeline.

---

## Explicitly not in scope here

- No changes to Increments 1–4 or the OpenAustralia Ingest/Interpretation pipeline.
- No attempt to backfill ministerial data for people without an `open_australia` identifier
  (pre-Federation-era or otherwise outside the existing pipeline's reach).
- Ministry (collective cabinet) grouping is flagged as a question, not designed here — see
  Phase 2's open questions.
