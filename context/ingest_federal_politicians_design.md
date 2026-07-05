# Ingest Federal Politicians — Design

## Goal

Fetch all current (and eventually historical) Australian federal politicians from the
OpenAustralia API and record them in the Lester graph as `Person` nodes, linked to their
party, chamber, and electorate/state.

---

## API: OpenAustralia

- Base URL: `https://www.openaustralia.org.au/api/`
- Auth: `key=<OPENAUSTRALIA_API_KEY>` query param on every request
- Output format: `output=js` returns JSON
- API key: stored in Rails credentials (key not yet wired up)
- Docs: https://www.openaustralia.org.au/api/

### Relevant endpoints

#### `getRepresentatives`
Returns all current House of Representatives members.

Optional params: `postcode`, `date`, `party`, `search`

Response fields per member:
- `member_id` — term-specific ID (changes if member is re-elected after a gap)
- `person_id` — stable cross-term ID (use this as the external identifier)
- `name` — full name string
- `party` — party affiliation string
- `constituency` — electorate name

#### `getSenators`
Returns all current Senators.

Optional params: `date`, `party`, `state`, `search`

Response fields: same shape as above; `constituency` is a state abbreviation (NSW, VIC, etc.)

#### `getRepresentative` (singular)
Returns enriched detail for one member, looked up by `person_id`.

Additional fields over the list response:
- `first_name`, `last_name`, `full_name`
- `entered_house`, `left_house` — ISO date strings for current/past term
- `entered_reason`, `left_reason` — e.g. "general_election", "dissolution"
- `title` — e.g. "Mr", "Dr"
- `image` — path to photo (`/images/mpsL/{person_id}.jpg`)
- `office` — array of ministerial/shadow positions with `from_date`, `to_date`, `dept`
- `lastupdate` — timestamp

#### `getSenator` (singular)
Same enriched shape as `getRepresentative`.

---

## HTTP client

Use **Faraday** (already in Gemfile, `>= 2.14.1`). No external gem for the API wrapper.
Thin `OpenAustralia::ApiClient` service wrapping Faraday — one method per endpoint.

---

## Data captured per politician

| Data | How stored |
|---|---|
| Name | `Person#name` (cleaned via `People::RecordPerson` / `cleaned_up_name`) |
| Stable API identity | `ExternalIdentifier` — `source: 'open_australia'`, `value: person_id` |
| Party | `Membership` → existing or new party `Tag` |
| Chamber | `Membership` → "House of Representatives" or "Senate" `Tag` |
| Electorate / State | `Membership` → electorate or state `Group` (TBD — see open questions) |

### Source name decision
Use `'open_australia'` (not `'open_politics'`). The existing value in
`ExternalIdentifier::SOURCES` is `'open_politics'` but that's a placeholder;
the actual source is OpenAustralia. Add `'open_australia'` to `SOURCES` and
migrate `'open_politics'` entries if any exist (currently zero).

---

## Implementation structure

Following the lobbyist ingestion pattern exactly:

```
app/sidekiq/open_australia/
  ingest_politicians_job.rb         # Sidekiq entry point, calls service
  import_politician_row_job.rb      # Per-person job, sidekiq_options lock: :until_executed

app/services/open_australia/
  ingest_politicians.rb             # Calls API for both chambers, dispatches row jobs
  api_client.rb                     # Faraday wrapper — get_representatives, get_senators,
                                    #   get_representative(person_id), get_senator(person_id)
  import_politician_row.rb          # Records one politician: Person + ExternalIdentifier
                                    #   + party/chamber/electorate memberships
```

---

## Job flow

```
IngestPoliticiansJob                        # weekly, current parliament only
  └─ OpenAustralia::IngestPoliticians.call(date: nil)
       ├─ ApiClient#get_representatives  → each row → ImportPoliticianRowJob.perform_async(...)
       └─ ApiClient#get_senators         → each row → ImportPoliticianRowJob.perform_async(...)

BackfillHistoricalPoliticiansJob            # one-shot, walks election dates
  └─ OpenAustralia::IngestPoliticians.call(date: "2022-05-21")
     OpenAustralia::IngestPoliticians.call(date: "2019-05-18")
     ... (each election date)

ImportPoliticianRowJob
  └─ OpenAustralia::ImportPoliticianRow.call(person_id:, member_id:, name:, party:, chamber:)
       ├─ ApiClient#get_representative(person_id) OR get_senator(person_id)
       │    → enriched: first_name, last_name, entered_house, left_house, office[]
       ├─ Entity::RecordEntityWithExternalId (source: 'open_australia', value: person_id)
       ├─ find-or-create party Tag → Membership
       ├─ find-or-create chamber Tag → Membership (with start_date / end_date from API)
       └─ (office positions — deferred, see open questions)
```

`person_id` is stable across terms, so re-processing a politician from an earlier election
date will hit the `find_entity_by_external_id` path and update rather than duplicate.

---

## Decisions made

1. **Enriched detail call** — YES. `ImportPoliticianRowJob` will call the singular endpoint
   (`getRepresentative` / `getSenator`) for every person to capture `entered_house`,
   `left_house`, `entered_reason`, `left_reason`, and `office` positions. Dates are
   important because we want ex-politicians too (see historical ingestion below).

2. **Electorates as Groups** — NO for now. The only exception would be if we can source
   electorate branch membership data for major parties (which would make the electorate
   node genuinely useful for traversal). Not pursued in this phase.

3. **Historical politicians** — YES. We want as many ex-politicians as possible.
   Strategy: query the API with the `date` parameter set to each federal election date,
   walking back through election cycles. The API returns the parliament as it stood on
   that date, so we accumulate members across terms.
   Known federal election dates to walk (add more as needed):
   - 2025-05-03
   - 2022-05-21
   - 2019-05-18
   - 2016-07-02
   - 2013-09-07
   - 2010-08-21
   - 2007-11-24
   - 2004-10-09
   - 2001-11-10
   - 1998-10-03
   - 1996-03-02
   The `person_id` is stable across terms, so re-ingesting someone who served multiple
   terms will find them by external identifier and update rather than duplicate.

4. **Scheduler wiring** — weekly refresh is fine for current members. Historical backfill
   is a one-shot job. To be wired into `config/sidekiq.yml`.

5. **`People::RecordPerson` extension** — call `Entity::RecordEntityWithExternalId`
   directly from `ImportPoliticianRow`, bypassing `RecordPerson`. Avoids adding another
   source-specific keyword arg to an already-busy service.

6. **Party Tags** — parties arrive as raw strings from the API (e.g. "Australian Labor Party",
   "Liberal Party of Australia"). Need a canonical mapping or normalisation step so they
   align with whatever strings AEC data uses for the same parties. To be worked out when
   writing `ImportPoliticianRow`.

## Open questions

- **`member_id` vs term Membership dates** — `member_id` is term-specific. If a person
  served two non-consecutive terms, they get two `member_id`s but one `person_id`. Should
  each term be a separate `Membership` (with `start_date`/`end_date` from the detail
  endpoint), or is one Membership per chamber sufficient? _Likely: one Membership per term
  with dates — to be decided when writing the row service._

- **Party string normalisation** — how closely do OpenAustralia party strings match what's
  already in the Tags table from AEC ingestion? Needs a quick audit once credentials are
  available and a first API call can be made.

---

## Codebase context (read before writing code)

### Existing ingestion pattern to follow

The lobbyist ingestion is the closest match to what we're building. Study these files:

```
app/sidekiq/au_lobbyists/ingest_lobbyists_job.rb          # Sidekiq job shell
app/sidekiq/au_lobbyists/import_lobbyists_people_row_job.rb  # Per-row job with sidekiq lock
app/services/au_lobbyists/ingest_lobbyists.rb             # Orchestrator (download → dispatch)
app/services/au_lobbyists/csv_importer.rb                 # Iterates rows, calls perform_async
```

Key pattern: the orchestrator calls `perform_async` with scalar args (strings/ints) for each
row. The row job does all the DB work. Row jobs use `sidekiq_options lock: :until_executed, on_conflict: :log, retry: 1`.

### `Entity::RecordEntityWithExternalId`
`app/services/entity/record_entity_with_external_id.rb`

This is what `ImportPoliticianRow` should call instead of `People::RecordPerson`. It:
1. Looks up `ExternalIdentifier` by `(source, owner_type, value)` — returns the owner if found.
2. Falls back to finding a sole `Person` by name and appending the external ID.
3. Creates a new `Person` if neither path finds a match.

Constructor: `new(name:, identifier:, source:, id_attribute:, klass:)`
- `identifier` = the `person_id` string from OpenAustralia
- `source` = `'open_australia'`
- `id_attribute` = whichever column on Person holds this (likely none — we rely purely on
  the `external_identifiers` table, so `id_attribute` may need a dummy or the service may
  need a small tweak for the no-column case)

**Watch out:** `find_sole_entity_by_name_and_append_external_id` calls
`entity.public_send(:"#{id_attribute}=", identifier)` — which assumes there's a column
on `Person` for the ID. Since `open_australia` IDs live only in `external_identifiers`
(no column on `people`), this will raise. We'll need to handle that — either skip the
setter or guard it. Worth checking when writing `ImportPoliticianRow`.

### `ExternalIdentifier` model
`app/models/external_identifier.rb`

```ruby
SOURCES = %w[aec acnc open_politics].freeze
```

Currently has zero rows for `open_politics`. We rename the source string to `'open_australia'`
and add it to SOURCES. No migration needed (it's just a string column), just update the constant.

### `People::RecordPerson`
`app/services/people/record_person.rb`

Worth knowing: it has a long `cleaned_up_name` method that strips titles (Hon, Dr, Senator, MP,
OAM, etc.), reverses "Last, First" format, and capitalises. Many of those transforms are exactly
what we need for OpenAustralia names, which can include titles. Consider calling this normalisation
logic from `ImportPoliticianRow` before passing the name to `RecordEntityWithExternalId`. The
safest approach: instantiate `People::RecordPerson` just to call `cleaned_up_name`, then pass
the result to `RecordEntityWithExternalId`.

### `Membership` model
Memberships have `start_date`, `end_date`, `evidence`, and `positions` (has_many Position with
`title`). For chamber memberships we'll set:
- `start_date` = `entered_house` from API
- `end_date` = `left_house` from API (nil if currently serving)
- `evidence` = `'https://www.openaustralia.org.au'`

For a politician who served two non-consecutive terms in the same chamber, create two separate
`Membership` records (the model allows this — see CLAUDE.md: "A person or sub-group can have
multiple memberships in the same group over time").

### Faraday HTTP client pattern
`app/services/au_lobbyists/file_downloader.rb` and `app/services/abn/fetch_business_names.rb`
are good examples of how other services use Faraday. The OpenAustralia API is simple HTTP GET
with query params — no auth headers, just `key=` in the query string.

Example request shape:
```
GET https://www.openaustralia.org.au/api/getRepresentatives?key=KEY&output=js&date=2022-05-21
```

Response is a JSON array of member objects (when `output=js`).

### Ruby gem we considered and rejected
The `openaustralia` gem (v1.0.1, ~2013) wraps all these endpoints but is ancient and unmaintained.
Not used. Raw Faraday only.

---

## Environment / credentials

API key stored at `Rails.application.credentials.open_australia.api_key`.
Key may already be present in credentials — to be confirmed once master.key is available
on the current machine.

---

## Status

- [x] API exploration complete
- [x] Design agreed (decisions above)
- [ ] Confirm API key in credentials (blocked: master.key not on current machine)
- [ ] `ApiClient` service written + manually tested against live API
- [ ] `ExternalIdentifier::SOURCES` updated to include `'open_australia'`
- [ ] `IngestPoliticians` service + `IngestPoliticiansJob` written
- [ ] `BackfillHistoricalPoliticiansJob` written
- [ ] `ImportPoliticianRow` service written (includes singular detail API call)
- [ ] Party string normalisation audited against existing Tags
- [ ] Membership-per-term vs single-Membership decision made
- [ ] Specs written
- [ ] Scheduler entry added to `config/sidekiq.yml` (weekly, current only)
- [ ] First live ingest run tested
