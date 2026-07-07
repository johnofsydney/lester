# Ingest Federal Politicians — Design

## Goal

Fetch all current and historical Australian federal politicians from the OpenAustralia API
and record them in the Lester graph as `Person` nodes, connected to their chamber, party,
and (in later phases) their ministerial offices and Cabinet.

---

## API: OpenAustralia

- Base URL: `https://www.openaustralia.org.au/api/`
- Auth: `key=VALUE` query param on every request
- Output: `output=js` returns JSON
- Docs: https://www.openaustralia.org.au/api/
- Credentials: `Rails.application.credentials.open_australia.api_key`
  (key may already be present — confirm once master.key is available on current machine)

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
- `house` — `"representatives"` or `"senate"` — used as ExternalIdentifier value on the chamber Group
- `office` — array of ministerial/shadow positions:
  `[{ position, from_date, to_date, dept, person, source }, ...]`
- `lastupdate` — timestamp

---

## Pre-import: deletion scope

Before re-running the import we delete "pure politician" Person records — those whose only
graph connections are to a chamber (House of Reps / Senate) and/or a party Tag.

Anyone who also appears in other contexts (lobbyist org, charity, government contractor, etc.)
is **excluded from deletion** — their political memberships get rebuilt but the Person record
is preserved.

This mirrors the ACNC people import pattern.

Implement as a scope (or class method) on `Person`, e.g.:

```ruby
Person.only_parliamentary_connections
# → people whose membership groups are ALL in: chamber Tags + party Tags
# → excludes anyone with a membership in any other Group type
```

Exact implementation TBD when writing the model code — likely uses a NOT EXISTS subquery
checking for memberships outside the permitted Tag set.

---

## Phase 1: Politicians, chambers, parties

### What gets created

#### Person
- Name cleaned via `People::RecordPerson#cleaned_up_name` (strips Hon, Dr, Senator, MP, etc.)
- `ExternalIdentifier`: `source: 'open_australia'`, `value: person_id.to_s`

#### Chamber Groups  (find-or-create once, not per politician)
Two Groups exist for the chambers:
- `"House of Representatives"` — `ExternalIdentifier` source `'open_australia'`, value `'representatives'`
- `"Senate"` — `ExternalIdentifier` source `'open_australia'`, value `'senate'`

Using ExternalIdentifiers on the Groups (not hardcoded IDs) means we can look them up
reliably without the hardcoded-ID antipattern already flagged in `improvement_candidates.md`.

#### Chamber Membership  (one per term)
Each term = one `Membership` record between the Person and the chamber Group.

| Field | Value |
|---|---|
| `start_date` | `entered_house` from API |
| `end_date` | `left_house` from API (nil if currently serving) |
| `evidence` | `'https://www.openaustralia.org.au'` |

A politician who served two non-consecutive terms in the same chamber gets two Membership
records. The model explicitly supports this ("multiple memberships in the same group over time").

Deduplication on re-import: find existing Membership by `(member: person, group: chamber,
start_date: entered_house)` — update `end_date` if changed, otherwise skip.

#### Party membership

Three cases based on the `party` field from the API:

**Independents** — party string is blank, `"Independent"`, or similar.
→ No party Membership created.

**Minor parties** (One Nation, Lambie Network, United Australia Party, Katter's Australian Party, etc.)
→ Membership in the national party Tag only. No state.

**Major parties** (Labor, Liberals, Nationals, Greens)
→ Membership in the **state branch** Tag.

State branch resolution:
- **Senators**: `constituency` from the API IS the state (NSW, VIC, QLD, WA, SA, TAS, ACT, NT). Straightforward.
- **MPs**: `constituency` is the electorate name, not the state. Requires an electorate → state
  lookup. Options:
  a. Maintain a lookup table in the codebase (all ~151 electorates mapped to states).
    get info from https://www.aec.gov.au/profiles/ and populate a mapper ruby file
  b. Call `getDivisions` API endpoint which may return state info per electorate.
  c. For Phase 1, fall back to national party Tag for MPs and revisit.
  _Decision: defer electorate→state mapping to Phase 1b. MPs get national party for now._
d. Make a call to  https://www.aec.gov.au/profiles/ to fetch State when we know electorate
State branch Tag naming convention (to align with AEC data — audit needed):
- `"Australian Labor Party (NSW)"` / `"Australian Labor Party (VIC)"` etc.
- `"Liberal Party of Australia (NSW Division)"` etc.
- Exact strings TBD pending audit of existing Tags in DB vs OpenAustralia party strings.

**Determining major vs minor**: use a constant list of major party strings in the service.
Anything not in the list and not independent → minor party → national Tag only.

```ruby
MAJOR_PARTIES = [
  /Australian Labor Party/i,
  /Liberal Party/i,
  /The Nationals/i,
  /Australian Greens/i,
].freeze
```

Note: Queensland has the "Liberal National Party of Queensland" (LNP) — a merged entity.
Treat as major (state branch). Will surface in audit.

---

## Phase 2: Offices and Ministries  (not in scope yet — design only)

OpenAustralia's `office` array contains ministerial and shadow ministerial positions with
date ranges. Phase 2 will:

### Ministerial offices

For each entry in `office`:
- Create a `Membership` between the Person and a **Department** Group
  (find-or-create by `dept` string, e.g. `"Department of Defence"`)
- Create a `Position` on that Membership with `title` = `position` string,
  `start_date` / `end_date` from `from_date` / `to_date`

### Ministries / Cabinets

A **Ministry** is the collective cabinet of a PM (e.g. "Morrison Ministry", "Albanese Ministry").
Each Ministry is a `Group`. Ministers have `Membership` in the Ministry Group with their
portfolio `Position`.

Identifying which Ministry a given office stint belongs to requires a lookup of PM tenure date
ranges (not provided by OpenAustralia directly — needs a separate lookup table or seed data).

This is complex enough to design separately when Phase 1 is complete.

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
         person_id:, name:, party:, constituency:, chamber:)
       ├─ ApiClient#get_representative(person_id) or get_senator(person_id)
       │    → enriched detail: entered_house, left_house, office[], etc.
       ├─ Clean name via People::RecordPerson.new(name).send(:cleaned_up_name)
       ├─ Entity::RecordEntityWithExternalId.call(
       │    name:, identifier: person_id, source: 'open_australia',
       │    id_attribute: nil [see gotcha below], klass: 'Person')
       ├─ Find-or-create chamber Group (via ExternalIdentifier on Group)
       ├─ Find-or-create chamber Membership (matched on person + group + start_date)
       ├─ Resolve party Tag (major/minor/independent logic)
       └─ Find-or-create party Membership
```

`person_id` is stable across terms — re-processing a politician from an earlier election date
hits `find_entity_by_external_id` and updates rather than duplicates.

---

## Codebase context (read before writing code)

### Lobbyist ingestion — the pattern to follow

```
app/sidekiq/au_lobbyists/ingest_lobbyists_job.rb
app/sidekiq/au_lobbyists/import_lobbyists_people_row_job.rb
app/services/au_lobbyists/ingest_lobbyists.rb
app/services/au_lobbyists/csv_importer.rb
```

Row jobs use: `sidekiq_options lock: :until_executed, on_conflict: :log, retry: 1`
Orchestrator passes only scalar args (strings/ints) to `perform_async`.

### `Entity::RecordEntityWithExternalId`
`app/services/entity/record_entity_with_external_id.rb`

Lookup chain: ExternalIdentifier match → sole name match → create new.

**Gotcha:** `find_sole_entity_by_name_and_append_external_id` calls
`entity.public_send(:"#{id_attribute}=", identifier)`, which assumes a column on the model.
Since `open_australia` IDs live only in `external_identifiers` (no column on `people`),
passing a real `id_attribute` will raise `NoMethodError`. Options:
- Pass `id_attribute: nil` and guard the setter in the service.
- Or subclass / monkey-patch for the no-column case.
- Simplest: just rescue `NoMethodError` in the service and skip the setter — the
  `ExternalIdentifier` record is created separately anyway.
_Resolve when writing `ImportPoliticianRow`._

### `ExternalIdentifier` model
`app/models/external_identifier.rb`

```ruby
SOURCES = %w[aec acnc open_politics].freeze
```

Action needed: replace `'open_politics'` with `'open_australia'` in SOURCES.
No migration needed (string column). Zero existing rows for `open_politics`.
ExternalIdentifiers will be created on **both Person and Group** (chamber Groups).

### `People::RecordPerson`
`app/services/people/record_person.rb`

Has `cleaned_up_name` (private) that strips Hon, Dr, Senator, MP, OAM, etc. and fixes
"Last, First" ordering. Call this before passing names to `RecordEntityWithExternalId`.
Safe approach: `People::RecordPerson.new(raw_name).send(:cleaned_up_name, raw_name)`.

### `Membership` model
Has `start_date`, `end_date`, `evidence`, `positions` (has_many Position with `title`).
Multiple Memberships per (person, group) pair are valid — used for multi-term politicians.

### Faraday pattern
See `app/services/au_lobbyists/file_downloader.rb` and `app/services/abn/fetch_business_names.rb`.
OpenAustralia is simple GET with query params — no auth headers.

```
GET https://www.openaustralia.org.au/api/getRepresentatives?key=KEY&output=js&date=2022-05-21
```

Response is a JSON array when `output=js`.

### Ruby gem — rejected
`openaustralia` gem (v1.0.1, ~2013) — ancient, unmaintained. Not used. Raw Faraday only.

---

## Open questions

- **Electorate → state mapping for MPs** — needed for state-branch party membership for
  Labor/Liberal/Nationals/Greens MPs. Options: hardcoded lookup table, `getDivisions` API call,
  or defer to Phase 1b. Currently deferred.

- **Party string audit** — how do OpenAustralia party strings compare with existing AEC-sourced
  Tags in the DB? Need a live API call + Tag query to compare. Blocked on master.key / credentials.

- **LNP (Queensland)** — "Liberal National Party of Queensland" is a merged Liberal-National entity.
  Treat as a single state-branch major party. Confirm handling when party strings are audited.

- **`Entity::RecordEntityWithExternalId` id_attribute gotcha** — needs a code-level fix
  before `ImportPoliticianRow` can run. See codebase context above.

---

## Status

- [x] API exploration complete
- [x] Phase 1 design agreed
- [x] Phase 2 design sketched (offices / ministries)
- [ ] Confirm API key in credentials  _(blocked: master.key not on this machine)_
- [ ] Audit party strings from API vs existing DB Tags  _(blocked: same)_
- [ ] `ExternalIdentifier::SOURCES` — replace `'open_politics'` with `'open_australia'`
- [ ] Fix / workaround `id_attribute` gotcha in `Entity::RecordEntityWithExternalId`
- [ ] `OpenAustralia::ApiClient` written + smoke-tested against live API
- [ ] `Person.only_parliamentary_connections` scope written
- [ ] `IngestPoliticians` service + `IngestPoliticiansJob` written
- [ ] `BackfillHistoricalPoliticiansJob` written
- [ ] `ImportPoliticianRow` service written
- [ ] Electorate → state lookup resolved (Phase 1b)
- [ ] Specs written
- [ ] Scheduler entry added to `config/sidekiq.yml`
- [ ] First live ingest run on staging
