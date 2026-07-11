# Ingest Federal Politicians — Design

## Goal

Fetch all current and historical Australian federal politicians from the OpenAustralia API
and record them in the Lester graph as `Person` nodes, connected to the Australian Federal
Parliament group, their party, and state branch (where applicable).

---

## API: OpenAustralia

- Base URL: `https://www.openaustralia.org.au/api/`
- Auth: `key=VALUE` query param on every request - Rails.application.credentials.dig(:open_australia, :api_key)
- Output: `output=js` returns JSON
- Docs: https://www.openaustralia.org.au/api/
- Credentials: `Rails.application.credentials.open_australia.api_key`

### Endpoints used

#### `getRepresentatives` / `getSenators`  (list)
Returns all members as of a given date (or today if no date given).

| Param | Notes |
|---|---|
| `date` | ISO date — returns parliament as it stood on that date. Key for historical ingestion. |
| `party` | Optional filter |
| `search` | Optional filter |
| `state` | Senators only |

Response fields per row:
- `member_id` — term-specific (changes if re-elected after a gap)
- `person_id` — **stable cross-term integer ID** — use as ExternalIdentifier value
- `name` — full name string (may include titles)
- `party` — party string e.g. `"Australian Labor Party"`
- `constituency` — electorate name for MPs; state abbreviation (NSW, VIC…) for Senators

#### `getRepresentative` / `getSenator`  (singular, by person_id)
Called inside each row job to get enriched detail.

Additional fields:
- `first_name`, `last_name`, `full_name`
- `entered_house` / `left_house` — ISO date strings for this term (`left_house` is blank if currently serving)
- `entered_reason` / `left_reason` — e.g. `"general_election"`, `"dissolution"`, `"died"`
- `title` — e.g. `"Mr"`, `"Dr"`
- `image` — `/images/mpsL/{person_id}.jpg`
- `house` — `"representatives"` or `"senate"` — used to set Position title
- `office` — array of ministerial/shadow positions (Phase 2, currently out of scope)
- `lastupdate` — timestamp

---

## Pre-import: deletion scope

Before re-running the import we delete "pure politician" Person records — those whose only
graph connections are to the Australian Federal Parliament group (or the NSW Parliament group) and one or more party groups.

Anyone who also appears in other contexts (lobbyist org, charity, government contractor,
state parliament, etc.) is **excluded from deletion** — their political memberships get
rebuilt but the Person record is preserved.

This mirrors the ACNC people import pattern.

```ruby
Person.only_parliamentary_connections
# -> include people who are members of a chamber and no other groups except for parties
```

Implemented as a scope on `Person` — see `app/models/person.rb`. ✅

---

## Phase 1: Politicians, parliament group, parties

### What gets created

#### Person
- Name cleaned via `People::RecordPerson#cleaned_up_name` (strips Hon, Dr, Senator, MP, etc.)
- `ExternalIdentifier`: `source: 'open_australia'`, `value: person_id.to_s`

#### Parliament Group  (find-or-create once, not per politician)

One Group for all federal parliamentarians:

- **`"Australian Federal Parliament"`** — `ExternalIdentifier` source `'open_australia'`, value `'federal_parliament'`

Using an ExternalIdentifier on the Group (not a hardcoded ID) means we can look it up
reliably without the hardcoded-ID antipattern flagged in `improvement_candidates.md`.

#### Parliament Membership  (one per term)

Each term returned by the API = one `Membership` record between the Person and the
Australian Federal Parliament group, with a `Position` recording the chamber role.

| Field | Value |
|---|---|
| `start_date` | `entered_house` from API |
| `end_date` | `left_house` from API (nil if currently serving) |
| `evidence` | `'https://www.openaustralia.org.au'` |

**Position on this Membership:**

| House | Position title |
|---|---|
| `"representatives"` | `"MP"` |
| `"senate"` | `"Senator"` |

A politician who served two non-consecutive terms gets two Membership records (each with
its own Position). The model explicitly supports multiple Memberships per (person, group).

Deduplication on re-import: find existing Membership by `(member: person, group: parliament,
start_date: entered_house)` — update `end_date` if changed, otherwise skip.

#### A note on Tags vs Groups

In Lester, a **Tag** is a category label — a Group subclass used as an umbrella.
**People are never direct members of a Tag.** Instead:

```
Tag: "Australian Labor Party"           ← category, no person members
  └── Group member: "ALP (Federal)"     ← branch Group
  └── Group member: "ALP (NSW)"         ← branch Group
        └── Person member: Alicia Payne ← politician
```

All party memberships for politicians are to **branch Groups**, not to the Tag itself.
The branch Group names are what `Group::NAMES` describes.

#### Party membership

Three cases based on the `party` field from the API:

**Independents** — party string is blank, `"Independent"`, or similar.
→ No party Membership created.

**Minor parties** (One Nation, Lambie Network, United Australia Party, Katter's Australian Party, etc.)
→ One Membership in a find-or-create Group named after the party string.
  Position title: `"Federal Parliamentary Party Member"`.
  Note: minor party Groups are not members of any Tag, so they will not be recognised
  as "parliamentary" by the `only_parliamentary_connections` deletion scope. Acceptable for Phase 1.

**Major parties** (Labor, Liberals, Nationals, Greens)
→ Two Memberships, both to branch Groups (never to the Tag itself):
  1. **Federal branch Group** — e.g. `"ALP (Federal)"` / `"Liberals (Federal)"` etc.
     Position title: `"Federal Parliamentary Party Member"`
     `start_date`: `entered_house` from API
  2. **State branch Group** — e.g. `"ALP (NSW)"` / `"Liberals (NSW)"` etc.
     Position title: `"Party Member (NSW)"` (state abbreviation inserted)
     No start_date (state branch membership has no term-specific date in the API)

State branch resolution:
- **Senators**: `constituency` from the API IS the state (NSW, VIC, QLD, WA, SA, TAS, ACT, NT). Straightforward.
- **MPs**: use `MapElectorateToState.lookup(constituency)` — see `app/mappings/map_electorate_to_state.rb`. ✅

Branch Group naming convention (from `Group::NAMES` — these are Group names, not Tag names):
- Labor: `"ALP (Federal)"`, `"ALP (NSW)"` etc.
- Liberals: `"Liberals (Federal)"`, `"Liberals (NSW)"` etc.
- Nationals: `"Nationals (Federal)"`, `"Nationals (NSW)"` etc.
- Greens: `"The Greens (Federal)"`, `"The Greens (NSW)"` etc.
- LNP (QLD): `"Liberal National Party (QLD)"` — treated as major, maps to `Group::NAMES.liberals[:qld]`

These branch Groups already exist in the DB as members of the `"australian labor party"`,
`"liberal / national coalition"`, and `"the greens"` Tags. Find them by name — do not
silently create if missing (raise instead, so a missing Group surfaces as a data issue).

**Determining major vs minor**: match the OpenAustralia party string against these patterns:

```ruby
MAJOR_PARTY_PATTERNS = [
  /Australian Labor Party/i,
  /Liberal Party/i,
  /The Nationals|^Nationals/i,
  /Australian Greens/i,
  /Liberal National Party/i,
].freeze
```

`Group::MAJOR_POLITICAL_GROUPS` lists the **Tag** names (`"Australian Labor Party"` etc.) —
useful for display/filtering queries but not for creating party Memberships.

**LNP (Queensland):** Members of the Liberal National Party of Queensland are treated as
Liberals. They receive the standard two-branch major-party treatment:
- Federal branch: `"Liberals (Federal)"` — `Group::NAMES.liberals[:federal]`
- State branch: `"Liberal National Party (QLD)"` — `Group::NAMES.liberals[:qld]`

`MapGroupNamesAecRecipients` already handles this: strings matching
`/(Liberal National Party|LNP).+(QLD|Queensland)/i` return `group_names.liberals.qld`,
and plain `"Liberal National Party"` falls through to `group_names.liberals.federal`.

---

## Phase 2: Offices and Ministries — REMOVED FROM SCOPE

The existing Ministry Group records and their associated Memberships are being deleted.
This phase will not be implemented.

---

## Implementation structure

Pattern: lobbyist ingestion (`app/sidekiq/au_lobbyists/`, `app/services/au_lobbyists/`).

```
app/sidekiq/open_australia/
  ingest_politicians_job.rb           # weekly Sidekiq job — current parliament only
  backfill_historical_politicians_job.rb  # one-shot — walks all election dates
  import_politician_row_job.rb        # per-person job (lock: :until_executed)

app/services/open_australia/
  ingest_politicians.rb               # calls API for both chambers, dispatches row jobs
  api_client.rb                       # Faraday wrapper
  import_politician_row.rb            # records one politician (Person + memberships)
```

---

## Job flow

```
IngestPoliticiansJob  (weekly)
  └─ OpenAustralia::IngestPoliticians.call(date: nil)
       ├─ ApiClient#get_representatives → ImportPoliticianRowJob.perform_async per row
       └─ ApiClient#get_senators        → ImportPoliticianRowJob.perform_async per row

BackfillHistoricalPoliticiansJob  (one-shot)
  └─ calls IngestPoliticians.call for each election date:
       2025-05-03, 2022-05-21, 2019-05-18, 2016-07-02, 2013-09-07,
       2010-08-21, 2007-11-24, 2004-10-09, 2001-11-10, 1998-10-03, 1996-03-02

ImportPoliticianRowJob
  └─ OpenAustralia::ImportPoliticianRow.call(
         person_id:, name:, party:, constituency:, house:)
       ├─ ApiClient#get_representative(person_id) or get_senator(person_id)
       │    → enriched detail: entered_house, left_house, house, etc.
       ├─ Find or create Person using People::RecordPerson (with ExternalIdentifier (source: 'open_australia'))
       ├─ Find-or-create "Australian Federal Parliament" using Group::RecordGroup (with ExternalIdentifier)
       ├─ Find-or-create parliament Membership (matched on person + group + start_date)
       │    + upsert Position ("MP" or "Senator") on that Membership
       ├─ Resolve state from constituency (MapElectorateToState for MPs, direct for Senators)
       ├─ Resolve party Groups (major/minor/independent logic)
       └─ Find-or-create federal party Membership + Position
          Find-or-create state branch Membership + Position (major parties only)
```

`person_id` is stable across terms — re-processing a politician from an earlier election date
hits the ExternalIdentifier lookup and updates rather than duplicates.

---

## Codebase context (read before writing code)

### Sidekiq conventions

Row jobs use: `sidekiq_options lock: :until_executed, on_conflict: :log, retry: 1`
Orchestrator passes only scalar args (strings/ints) to `perform_async`.

### `Entity::RecordEntityWithExternalId`
`app/services/entity/record_entity_with_external_id.rb`

Lookup chain: ExternalIdentifier match → sole name match → create new.

**Gotcha:** `find_sole_entity_by_name_and_append_external_id` calls
`entity.public_send(:"#{id_attribute}=", identifier)`, which assumes a column on the model.
Since `open_australia` IDs live only in `external_identifiers`, the `ExternalIdentifiable`
concern needs `open_australia_id` / `open_australia_id=` virtual attributes added — same
pattern as `aec_id`. Then pass `id_attribute: 'open_australia_id'`.

### `ExternalIdentifier` model
`app/models/external_identifier.rb`

```ruby
SOURCES = %w[aec acnc open_politics].freeze
```

Action needed: replace `'open_politics'` with `'open_australia'` in SOURCES.
No migration needed (string column). Zero existing rows for `open_politics`.
ExternalIdentifiers are created on **both Person and Group** (parliament Group).

### `People::RecordPerson`
`app/services/people/record_person.rb`

This is the **single entry point** for recording a person — used consistently across all
ingestion pipelines. `ImportPoliticianRow` must use it for the same reason.

Pass the **raw name from the API** and the `open_australia_id:` keyword arg. `RecordPerson`
runs `cleaned_up_name` internally (strips Hon, Dr, Senator, MP, OAM, "Last, First" etc.)
before delegating to `Entity::RecordEntityWithExternalId`. Do not pre-clean the name in
`ImportPoliticianRow` — let `RecordPerson` own that step.

```ruby
People::RecordPerson.call(raw_name, open_australia_id: person_id)
```

`RecordPerson` needs to be extended with `open_australia_id:` alongside the existing
`aec_id:` and `acnc_id:` keyword args, and `ExternalIdentifiable` needs
`open_australia_id` / `open_australia_id=` virtual attributes added (same pattern as
`aec_id`). Then `id_attribute: 'open_australia_id'` flows through to
`RecordEntityWithExternalId` correctly.

### `Groups::RecordGroup`
`app/services/groups/record_group.rb`

The **single entry point** for recording a group — equivalent to `People::RecordPerson`
for the group side. Used for both the parliament Group and (via the mapper) for locating
party branch Groups.

**Parliament Group** (find-or-create once, anchored by ExternalIdentifier):

```ruby
Groups::RecordGroup.call('Australian Federal Parliament', open_australia_id: 'federal_parliament')
```

**Party branch Groups** (found by normalised name via mapper; mostly already exist in the DB):

```ruby
Groups::RecordGroup.call(party_string_from_api, mapper: MapGroupNamesAecRecipients.new)
```

`MapGroupNamesAecRecipients` already handles all the major party normalisation patterns
(Labor, Liberals, Nationals, Greens, LNP, etc.) and returns the canonical branch Group
name (`"ALP (Federal)"`, `"Liberals (NSW)"`, etc.) used in `Group::NAMES`.

`RecordGroup` needs to be extended with `open_australia_id:` alongside the existing
`aec_id:` and `acnc_id:` keyword args — the same treatment required for `RecordPerson`.
The same `external_id` branching logic applies: when `open_australia_id:` is present,
set `@source = 'open_australia'`, `@identifier = open_australia_id.to_s`,
`@id_attribute = 'open_australia_id'` and delegate to
`Entity::RecordEntityWithExternalId`. See `improvement_candidates.md` item #6 for the
longer-term fix to this per-source arg proliferation.

### `Membership` + `Position` models
`Membership` has `start_date`, `end_date`, `evidence`, `positions` (has_many Position).
`Position` has `title`, `start_date`.
Multiple Memberships per (person, group) pair are valid — used for multi-term politicians.

### Faraday pattern
See `app/services/au_lobbyists/file_downloader.rb` and `app/services/abn/fetch_business_names.rb`.
OpenAustralia is simple GET with query params — no auth headers.

```
GET https://www.openaustralia.org.au/api/getRepresentatives?key=KEY&output=js&date=2022-05-21
```

Response is a JSON array when `output=js`.

### `MapElectorateToState`
`app/mappings/map_electorate_to_state.rb` — 150 electorates mapped to state abbreviations.
`MapElectorateToState.lookup('Eden-Monaro')` → `'NSW'`. ✅

### Ruby gem — rejected
`openaustralia` gem (v1.0.1, ~2013) — ancient, unmaintained. Not used. Raw Faraday only.

---

## Testing approach

Specs live under `spec/services/open_australia/` and `spec/sidekiq/open_australia/`.

**API fixtures** — real API responses are downloaded once and saved as JSON files under
`spec/fixtures/open_australia/`. Specs load these fixtures rather than hitting the live API.
This lets the mapper and row-import logic be iterated on quickly without network calls, and
makes the test suite deterministic.

If the mapper produces unexpected Group names during a real ingest run (creating a new Group
instead of finding an existing branch), adjust `MapGroupNamesAecRecipients` to handle the
new OpenAustralia party string, update the fixture if needed, and re-run specs. Do not
pre-audit party strings in isolation — let real data surface the gaps.

---

---

## Status

- [x] API exploration complete
- [x] Phase 1 design agreed
- [x] Phase 2 removed — Ministry Groups and Memberships to be deleted
- [x] Confirm API key in credentials
- [ ] Audit party strings from API vs existing DB Tags
- [ ] `ExternalIdentifier::SOURCES` — replace `'open_politics'` with `'open_australia'`
- [ ] `ExternalIdentifiable` — add `open_australia_id` / `open_australia_id=` virtual attribute
- [ ] `People::RecordPerson` — add `open_australia_id:` kwarg + routing branch
- [ ] `Groups::RecordGroup` — add `open_australia_id:` kwarg + routing branch
- [ ] `OpenAustralia::ApiClient` written + smoke-tested against live API
- [x] `Person.only_parliamentary_connections` scope written + specced
- [x] `MapElectorateToState` mapping file created (150 electorates)
- [ ] `IngestPoliticians` service + `IngestPoliticiansJob` written
- [ ] `BackfillHistoricalPoliticiansJob` written
- [ ] `ImportPoliticianRow` service written
- [ ] Scheduler entry added to `config/sidekiq.yml`
- [ ] First live ingest run on staging
