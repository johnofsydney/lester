# Ingest Local Councillors — Design

## Goal

Record a `Person` node for every elected local councillor and senior executive officer
across all Australian local councils, connected to their council Group and (where available)
their political party.

Australia has approximately 500–540 local councils. Each has its own website with a
councillor/staff listing page of varying structure. There is no central API or authoritative
data source — each council must be scraped individually.

---

## Scope

### In scope

- **Elected councillors** — all current councillors for every local council in Australia
- **Executive management** — CEO, General Manager, Directors, and equivalent senior roles
  (non-elected but relevant to the transparency mission)
- **Mayor / Deputy Mayor** — recorded via Position title on the council Membership
- **Party affiliation** — recorded where the council website lists it (common in NSW and QLD;
  rare or absent in most other states)

### Out of scope (Phase 1)

- Historical councillors (previous terms)
- Committee memberships within a council
- State-level local government bodies (e.g. Local Government NSW)

---

## Data model

### How it fits into the existing graph

```
Tag: "Australian Local Councils"             ← category Tag
  └── Group member: "City of Sydney Council" ← one Group per council
        └── Person member: Clover Moore      ← councillor
        └── Person member: Jane Smith        ← councillor
  └── Group member: "Waverley Council"
        ...
```

People are **never** direct members of the Tag — same pattern as political parties.

### Council Group

- **Name**: council's full official name (e.g. `"City of Sydney Council"`,
  `"Waverley Council"`, `"Brisbane City Council"`)
- **ExternalIdentifier**: `source: 'abs'`, `value: ABS Local Government Area (LGA) code`
  — the ABS publishes a definitive list of LGA codes which provides a stable, unique ID
  per council. This avoids the hardcoded-ID antipattern.
- **Tag membership**: Group is a member of the `"Australian Local Councils"` Tag

### Councillor Membership

| Field | Value |
|---|---|
| `member` | Person |
| `group` | Council Group |
| `start_date` | Term start date (where available — often not) |
| `end_date` | nil (currently serving) |
| `evidence` | URL of the councillor listing page |

**Position title** on the Membership:
- `"Councillor"` — standard elected member
- `"Mayor"` — where identified as Mayor on the page
- `"Deputy Mayor"` — where identified

### Executive officer Membership

Same structure as councillor, with Position titles like `"Chief Executive Officer"`,
`"General Manager"`, `"Director of Planning"`, etc. — scraped from the page as-is.

### Party affiliation

Where the council website lists a party for a councillor, create a Membership in the
corresponding party branch Group (same approach as the federal politician ingestion).
Where no party is listed, create no party Membership — do not infer or assume.

---

## The council registry

Before scraping can begin, a **registry** of all councils must be assembled. This is a
structured list of every council with at minimum:

- Council name (canonical)
- ABS LGA code (stable external ID)
- State / territory
- Councillor listing page URL
- Executive listing page URL (may be same page or separate)
- Scraper strategy identifier (see below)

The registry is the hardest part of the project. It is a one-time manual research effort
to find ~500 URLs, validate them, and keep them updated as councils redesign their sites.

**Proposed format**: a CSV file committed to the repo at
`csv_data/local_councils_registry.csv`, with columns:

```
lga_code, state, council_name, councillor_url, executive_url, scraper_strategy
```

The ABS publishes LGA codes and names at:
https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files

---

## Scraping architecture

### The core problem

Each council website is different. However, many councils use the same underlying CMS
platforms (Squiz Matrix, Open Cities, SilverStripe, Drupal, Council CMS by Indue, etc.)
which produce predictable HTML structure. The scraping strategy should be:

1. **Parameterised strategy** — a config-driven scraper that takes CSS selectors for name,
   role, party, and image. Covers the majority of councils that share a CMS pattern.
2. **Custom scraper** — a per-council Ruby class for councils with truly unusual pages
   (JavaScript-rendered content, PDFs, unusual layouts). Written case by case.

### Scraper strategy identifier

The `scraper_strategy` field in the registry maps to either:
- A named config key (e.g. `"squiz_matrix"`, `"open_cities"`) for parameterised scrapers
- A class name (e.g. `"BrisbaneCityCouncilScraper"`) for custom scrapers

### File structure

```
app/sidekiq/local_councils/
  ingest_local_councils_job.rb          # orchestrator — iterates registry, enqueues per-council
  import_council_job.rb                  # per-council Sidekiq job

app/services/local_councils/
  ingest_local_councils.rb              # loads registry CSV, dispatches jobs
  import_council.rb                      # top-level per-council service
  scraper_strategies/
    base_scraper.rb                      # shared interface / helpers
    parameterised_scraper.rb             # config-driven scraper (CSS selectors)
    custom/
      brisbane_city_council_scraper.rb   # example custom scraper
      ...

csv_data/
  local_councils_registry.csv           # the registry (see above)

spec/services/local_councils/
  import_council_spec.rb
  scraper_strategies/
    parameterised_scraper_spec.rb

spec/fixtures/local_councils/
  <council_slug>.html                   # saved HTML snapshots for specs
```

### Scraping approach

Use **Nokogiri** (already available in most Rails apps via ActiveSupport) for HTML
parsing. For JavaScript-rendered pages, fall back to **Ferrum** or **Playwright**
(headless Chrome). Avoid adding a heavy dependency unless needed — check first whether
the councillor data is in the initial HTML response.

### Record flow per council

```
ImportCouncil.call(registry_row)
  ├─ Fetch councillor page HTML
  ├─ Select scraper strategy (parameterised or custom class)
  ├─ Extract array of { name:, role:, party: } hashes
  ├─ Find-or-create council Group (Groups::RecordGroup, lga_code as external ID)
  ├─ Ensure council Group is a member of "Australian Local Councils" Tag
  └─ For each extracted person:
       ├─ People::RecordPerson.call(name)  ← no external ID available for most councils
       ├─ Find-or-create Membership (person → council Group)
       ├─ Upsert Position (title from role field)
       └─ If party present: find-or-create party Membership (via mapper)
```

### Person disambiguation

This is the hardest problem in the project. Unlike federal politicians (who have a
stable `person_id` from OpenAustralia), local councillors have no universal identifier.
The only available key is their **name**, which is unreliable (common names, name
variants). `People::RecordPerson` will fall back to name matching, which risks:

- Merging two different people with the same name
- Creating duplicate records for the same person under slightly different name spellings

Mitigations:
- Scoping: a person named "John Smith" who is only a local councillor is unlikely to
  collide with an AEC donor named "John Smith" — different context, different Groups.
  But it will happen eventually.
- Long-term: the `ExplodePerson` admin action already exists to split falsely-merged
  records.
- See `context/person_disambiguation_design.md` for the broader plan.

For Phase 1, accept name-match ambiguity and plan to clean up edge cases manually.

---

## Building the registry — suggested approach

Manual assembly of 500+ URLs is a significant effort. Suggested phased approach:

1. **Start with the major councils** (top ~50 by population) to prove the scraping
   patterns work before investing in the full registry.
2. **Use state government LGA lists** as the authoritative source of council names and
   codes — each state publishes these (e.g. NSW: Office of Local Government; VIC: DELWP;
   QLD: LGAQ).
3. **Identify CMS patterns** across the first 50 councils — likely reveals 3–5 common
   templates that cover 70%+ of the remainder.
4. **Crowdsource or automate URL discovery**: given a council name, attempt to find
   the councillor page URL via a search API (e.g. Google Custom Search or Bing) and
   validate programmatically.

---

## Open questions

- **ABS LGA codes** — confirm these are stable across census cycles and usable as
  external IDs. Some councils amalgamate, split, or are abolished — need a handling
  strategy for discontinued councils.
- **Executive officers** — is the CEO/GM always a separate page? Or combined with
  councillors? Needs investigation per council.
- **JavaScript-rendered pages** — what fraction of councils require a headless browser?
  Sample the first 50 to estimate.
- **Re-scrape frequency** — councillors change after local elections (held on different
  cycles per state: NSW every 4 years, VIC every 4 years, QLD every 4 years, etc.).
  Scheduler cadence TBD.
- **Party mapper** — `MapGroupNamesAecRecipients` was built for AEC data. Local council
  party strings will be different (e.g. "Labor", "Liberal", "Greens", plus many local
  tickets and independents). A new `MapGroupNamesLocalCouncils` mapper will likely be needed.

---

## Status

- [ ] Registry: assemble list of all ~540 councils with LGA codes
- [ ] Registry: find councillor page URL for top 50 councils
- [ ] Identify common CMS patterns across top 50
- [ ] `BaseScraper` + `ParameterisedScraper` written and specced
- [ ] `ImportCouncil` service written and specced
- [ ] `IngestLocalCouncils` service + `IngestLocalCouncilsJob` written
- [ ] `ImportCouncilJob` written
- [ ] "Australian Local Councils" Tag seeded
- [ ] `MapGroupNamesLocalCouncils` mapper written
- [ ] First 50 councils imported and validated
- [ ] Full registry assembled and all councils imported
- [ ] Scheduler entry added to `config/sidekiq.yml`
