# Web Scraper Pipeline — Design

## Goal

A general-purpose scraping pipeline for ingesting structured people-and-roles data from
external websites. The first use case is Australian local council councillors, but the
architecture is explicitly designed to extend to any entity type: company boards, superannuation
fund leadership teams, industry body committees, university governance, and so on.

The pipeline is convention-driven: adding a new scraper requires only dropping a class file
into the right folder. No config changes, no scheduler entries, no job registrations needed.

---

## Generalised data model

The graph pattern is the same regardless of entity type:

```
Tag: "Australian Local Councils"             ← category Tag (one per entity type)
  └── Group: "City of Sydney Council"        ← one Group per scraped entity
        └── Person: Clover Moore             ← member
        └── Person: Jane Smith               ← member
  ...

Tag: "ASX 200 Company Boards"
  └── Group: "BHP Group"
        └── Person: Ken MacKenzie            ← board member
  ...

Tag: "Superannuation Funds"
  └── Group: "Australian Super"
        └── Person: Paul Schroder            ← CEO
  ...
```

People are **never** direct members of a Tag — same pattern as political parties.

Each scraped Group is found or created by its canonical name (which the scraper class owns as
a constant). Once created the Group has a stable DB ID. There is no external API handing us
a stable identifier — the data comes from individual websites that publish no such thing.

---

## Scraper class conventions

### File location

All scraper classes live under `app/services/web_scrapers/`. Sub-namespaces organise by
entity type:

```
app/services/web_scrapers/
  base.rb
  local_councils/
    city_of_sydney_council.rb      # → WebScrapers::LocalCouncils::CityOfSydneyCouncil
    waverley_council.rb
    brisbane_city_council.rb
    ...
  company_boards/
    bhp_group.rb                   # → WebScrapers::CompanyBoards::BhpGroup
    ...
  super_funds/
    australian_super.rb            # → WebScrapers::SuperFunds::AustralianSuper
    ...
```

The nightly scheduler discovers scrapers by finding all subclasses of `WebScrapers::Base`
via `ObjectSpace`. Because Zeitwerk eagerly loads `app/services/**/*` in production and
test, any class dropped in this tree is automatically available — no require, no registration.

### Base class interface

```ruby
class WebScrapers::Base
  # Subclasses must define:
  ENTITY_NAME = 'Human-readable name'.freeze   # used in run log and admin UI
  CADENCE     = 30.days                        # how often to re-scrape

  def self.call = new.call

  def call
    raise NotImplementedError
  end
end
```

A minimal scraper looks like:

```ruby
class WebScrapers::LocalCouncils::WaverleyCouncil < WebScrapers::Base
  ENTITY_NAME = 'Waverley Council'.freeze
  CADENCE     = 30.days

  def call
    html      = fetch('https://www.waverley.nsw.gov.au/council/councillors')
    people    = parse(html)
    group     = find_or_create_group
    record_people(group, people)
  end

  private
  # ... scraping/parsing/recording logic
end
```

The class file location is the only registration step needed.

---

## Scheduler — single nightly job

One Sidekiq-scheduler entry replaces what would otherwise be hundreds of per-entity cron
lines. The nightly job:

1. Finds all `WebScrapers::Base` subclasses (via `ObjectSpace.each_object(Class)`)
2. For each, checks `ScraperRun.last_success_for(scraper_class)` → `completed_at`
3. If `completed_at.nil? || completed_at < CADENCE.ago`: enqueues `WebScrapers::RunJob`
4. If already queued or running (check `scraper_runs` status): skips

```
config/sidekiq.yml:
  web_scraper_nightly_job:
    cron: '0 18 * * *'   # Every night at 4am AEST
    class: WebScrapers::NightlySchedulerJob
```

This is the only scheduler entry the pipeline ever needs, regardless of how many scrapers
exist.

---

## Job wrapper

A single generic Sidekiq job receives the scraper class name as a string argument,
instantiates the class, runs it, and handles logging:

```ruby
class WebScrapers::RunJob
  include Sidekiq::Job

  sidekiq_options(
    lock:        :until_executed,
    on_conflict: :log,
    retry:       3
  )

  def perform(scraper_class_name)
    scraper_class = scraper_class_name.constantize
    run           = ScraperRun.start!(scraper_class_name)

    scraper_class.call

    run.succeed!
  rescue StandardError => e
    run&.fail!(e)
    raise
  end
end
```

Because retries are handled by Sidekiq (up to 3 attempts), `ScraperRun#fail!` is only
called on the final failure (after exhausting retries) — otherwise Sidekiq re-enqueues
automatically.

---

## Run log — `scraper_runs` table

Every job attempt is recorded. This table drives both the admin dashboard and the nightly
scheduler's "is it due?" check.

| Column | Type | Notes |
|---|---|---|
| `scraper_class` | string | e.g. `"WebScrapers::LocalCouncils::CityOfSydneyCouncil"` |
| `entity_name` | string | from `ENTITY_NAME` constant — human-readable |
| `status` | string | `"running"` / `"success"` / `"failed"` |
| `started_at` | datetime | |
| `completed_at` | datetime | nil until finished |
| `error_message` | text | nil on success; exception message + first 5 lines of backtrace on failure |
| `records_created` | integer | optional — scrapers can report this |
| `records_updated` | integer | optional |

```ruby
class ScraperRun < ApplicationRecord
  scope :last_success_for, ->(klass) {
    where(scraper_class: klass.to_s, status: 'success').order(completed_at: :desc).first
  }
end
```

---

## Admin dashboard

ActiveAdmin resource at `/admin/scraper_runs`:

- **Index**: table of all runs, most recent first. Columns: entity name, scraper class,
  status (colour-coded), started_at, duration, records created/updated.
- **Filters**: status, entity name (search), date range, scraper namespace (local_councils /
  company_boards / etc.)
- **Show**: full error_message and backtrace for failed runs.
- **Manual trigger**: a custom action to enqueue `WebScrapers::RunJob` immediately for a
  given scraper class, bypassing the nightly cadence check. Useful for re-running a failed
  scraper or testing a new one.

---

## Local councils — first use case

### Council Group

- **Name**: council's full official name (e.g. `"City of Sydney Council"`) — defined as a
  constant in the scraper class and used as the find-or-create key on every re-scrape
- **No ExternalIdentifier** — the council websites publish no stable machine-readable ID,
  and ABS LGA codes are a geography reference we would have to manually curate, not something
  the scraped data provides
- **Tag membership**: Group is a member of the `"Australian Local Councils"` Tag

### Councillor Membership

| Field | Value |
|---|---|
| `member` | Person |
| `group` | Council Group |
| `start_date` | Term start date (where available — often not) |
| `end_date` | nil (currently serving) |
| `evidence` | URL of the councillor listing page |

**Position titles**: `"Councillor"`, `"Mayor"`, `"Deputy Mayor"`.

### Executive officer Membership

Same structure, with Position titles scraped as-is from the page (`"Chief Executive Officer"`,
`"General Manager"`, `"Director of Planning"`, etc.).

### Party affiliation

Where the council website lists a party, create a Membership in the corresponding party
branch Group. Where not listed, create no party Membership. A new
`MapGroupNamesLocalCouncils` mapper will be needed — local council party strings differ from
AEC strings (e.g. `"Labor"` not `"Australian Labor Party"`).

### Council registry

Before scraping begins, a registry CSV must be assembled at `csv_data/local_councils_registry.csv`:

```
state, council_name, councillor_url, executive_url
```

The scraper strategy is no longer a registry field — it lives in the scraper class itself.
Each class knows how to scrape its own council. The registry provides the stable external
data (LGA codes and URLs); the class provides the parsing logic.

The registry is a one-time manual research effort (~540 rows). The LGA code column is
retained as a human reference only (useful for disambiguation when two councils share similar
names), not as a database key. Suggested phased approach:

1. Start with the top ~50 councils by population
2. Write scraper classes for those 50 — identify which CMS patterns are most common
3. Build shared parsing utilities for the common patterns
4. Expand to full 540

### Scraping utilities

Common scraping needs are extracted into shared helpers that scraper classes can use:

```
app/services/web_scrapers/
  base.rb
  html_fetcher.rb           # Faraday-based HTTP fetch with error handling
  scraper_strategies/
    nokogiri_scraper.rb     # HTML parsing helpers (CSS selector extraction)
    headless_scraper.rb     # Ferrum-based fallback for JS-rendered pages
```

Scraper classes include whichever helpers they need. No inheritance chain beyond `Base`.

### Person disambiguation

Local councillors have no universal ID. `People::RecordPerson` falls back to name matching,
which risks merges and duplicates. Accept this for Phase 1; `ExplodePerson` exists for
manual cleanup. See `context/person_disambiguation_design.md`.

---

## Full file structure

```
app/models/
  scraper_run.rb

app/services/web_scrapers/
  base.rb
  html_fetcher.rb
  scraper_strategies/
    nokogiri_scraper.rb
    headless_scraper.rb
  local_councils/
    city_of_sydney_council.rb
    ...
  company_boards/
    ...
  super_funds/
    ...

app/sidekiq/web_scrapers/
  nightly_scheduler_job.rb
  run_scraper_job.rb

app/admin/
  scraper_runs.rb

db/migrate/
  ..._create_scraper_runs.rb

csv_data/
  local_councils_registry.csv

spec/services/web_scrapers/
  local_councils/
    city_of_sydney_council_spec.rb
  ...

spec/fixtures/web_scrapers/
  local_councils/
    city_of_sydney_council.html    # saved HTML snapshots
  ...
```

---

## Open questions

- **ABS LGA codes** — stable across most census cycles but some councils amalgamate or are
  abolished. Need a handling strategy (mark as inactive, preserve historical data).
- **JavaScript-rendered pages** — what fraction of councils require a headless browser?
  Sample the first 50 to estimate before investing in Ferrum.
- **`ExternalIdentifier`** — not used by this pipeline. No external system provides stable
  IDs for web-scraped entities. Group lookup is by canonical name; Person lookup is by name.
- **`scraper_runs` retry semantics** — clarify whether `ScraperRun#fail!` is called on
  every Sidekiq retry attempt or only on final exhaustion (see Sidekiq death callbacks).
- **Manual trigger auth** — admin dashboard trigger should require confirmation (destructive
  in the sense that it re-scrapes and may create duplicate records if idempotency is imperfect).

---

## Status

- [ ] `scraper_runs` migration + model + `ScraperRun` class
- [ ] `WebScrapers::Base` base class
- [ ] `WebScrapers::RunJob` generic job wrapper
- [ ] `WebScrapers::NightlySchedulerJob` + scheduler entry in `config/sidekiq.yml`
- [ ] ActiveAdmin `scraper_runs` dashboard
- [ ] `HtmlFetcher` utility
- [ ] `NokogiriScraper` strategy utility
- [ ] Confirm no `ExternalIdentifier` changes needed (no external IDs in scraped data)
- [ ] `"Australian Local Councils"` Tag seeded
- [ ] `MapGroupNamesLocalCouncils` mapper
- [ ] Registry CSV: assemble top 50 councils with LGA codes and URLs
- [ ] Write scraper classes for top 50 councils
- [ ] First 50 councils imported and validated
- [ ] Full registry assembled (~540 councils)
- [ ] `HeadlessScraper` strategy (if needed after sampling the first 50)
