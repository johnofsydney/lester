# Government Grants Ingestion — Design Document

**Status:** Proposed

## Current status (2026-07-19)

**Design only — no code written yet.** Nothing in `app/services`, `app/sidekiq`, or `db/schema.rb` implements any part of this pipeline (no `AuGrants` namespace, no `government_grants`/`government_grant` enum values). This is a full design pass, not a partially-built increment — treat every "Proposed" / "Planned" section below as not started.

Before implementation starts, resolve open question #1 (VALUE cumulative-vs-per-grant, see below) — the doc already flags this as the critical blocker.

---

## Goal

Ingest Australian Commonwealth awarded grants from GrantConnect into the existing Transfer/IndividualTransaction model, mirroring the AusTender contracts pipeline.

---

## Data Source: GrantConnect

**Site:** https://www.grants.gov.au
**Coverage:** All Commonwealth grant awards, mandatory reporting since 31 Dec 2017.

---

## Download Endpoints

### Primary: `GaPublishedDownload` (preferred)

Two-step process — the download endpoint requires a session cookie established by visiting the show page first:

**Step 1 — establish session (GET, capture cookies):**
```
GET https://www.grants.gov.au/Reports/GaPublishedShow
  ?AgencyStatus=0
  &DateType=Publish%20Date
  &DateStart=05-Jan-2026
  &DateEnd=05-Jan-2026
```

**Step 2 — download XLSX (GET, send cookies):**
```
GET https://www.grants.gov.au/Reports/GaPublishedDownload
  ?AgencyStatus=0
  &DateType=Publish%20Date
  &DateStart=05-Jan-2026
  &DateEnd=05-Jan-2026
```

- Response: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- No user account required — session cookie from step 1 is sufficient
- `DateType=Publish Date` with `DateStart`/`DateEnd` is the date filter
- Date format: `DD-Mon-YYYY` (e.g. `05-Jan-2026`)
- Single-day queries work fine; range queries also work

### Secondary: `GaAdvancedSearchDownload` (simpler, less data)

```
GET https://www.grants.gov.au/Search/GaAdvancedSearchDownload
  ?Page=1&ItemsPerPage=0&SearchFrom=AdvancedSearch&Type=Ga
  &AgencyStatus=0&KeywordTypeSearch=AllWord
  &DateType=Publish%20Date
  &DateStart=01-Jul-2025&DateEnd=01-Aug-2025
  &LastedVariation=True&OrderBy=Relevance
```

- Single GET, no session required
- Returns 15 columns — **no Recipient ABN**
- `LastedVariation=True` returns only the latest version of each amended grant
- Discovery: the `GaAdvancedSearch` HTML page contains an href to `GaAdvancedSearchDownload`

**Use `GaPublishedDownload` as the primary path** — it includes ABN and richer fields.

---

## XLSX Structure: `GaPublishedDownload`

Sheet name: `GrantConnect-Grant-Award-Publis`

- Rows 1–22: metadata/criteria summary — **skip**
- Row 23: column headers
- Row 24+: data rows

### Columns (row 23, all 32)

| # | Column | Notes |
|---|--------|-------|
| 1 | Agency | Granting department → **giver** |
| 2 | GA ID | Unique grant award ID → `external_id`. No version suffix here (unlike Advanced Search) |
| 3 | Internal Reference ID | Agency's internal ref — may be useful as secondary key |
| 4 | GO ID | Grant Opportunity ID (links to the original opportunity) |
| 5 | Recipient Name | Organisation or person name → **taker** |
| 6 | **Recipient ABN** | ABN string (e.g. `79 145 583 099`) or `"ABN Exempt"` |
| 7 | PBS Program Name | Budget program classification |
| 8 | Grant Program | Funding program name |
| 9 | Grant Activity | Specific activity/scheme name |
| 10 | Purpose | Full description (can be multi-line) |
| 11 | One-off/Ad hoc | `"Y"` / `"N"` |
| 12 | Aggregate | `"Y"` / `"N"` |
| 13 | Aggregate Reason | Text if aggregated |
| 14 | Aggregate Number | Integer (nil if not aggregate) |
| 15 | Selection Process | e.g. `"Open Competitive"`, `"Demand Driven"` |
| 16 | Category | e.g. `"Legal Services"`, `"Broadcasting and Telecommunications"` |
| 17 | Confidentiality - Contract | `"Y"` / `"N"` |
| 18 | Confidentiality - Outputs | `"Y"` / `"N"` |
| 19 | Publish Date | Ruby Date object |
| 20 | Approval Date | Ruby Date object |
| 21 | Start Date | Ruby Date object |
| 22 | End Date | Ruby Date object |
| 23 | **Value (AUD)** | Decimal float (e.g. `5341639.0`) — see note on cumulative vs per-grant below |
| 24 | Recipient Suburb | |
| 25 | Recipient Town/City | |
| 26 | Recipient Postcode | |
| 27 | Recipient State/Territory | |
| 28 | Recipient Country | |
| 29 | Delivery State/Territory | |
| 30 | Delivery Postcode | |
| 31 | Delivery Country | |
| 32 | Contact Name | Agency contact |

### Observed data examples

```
Agency:         Attorney-General's Department
GA ID:          GA523939
Recipient Name: n/a
Recipient ABN:  ABN Exempt
Value (AUD):    20000.0
Publish Date:   2026-01-05

Agency:         Dept of Infrastructure, Transport, Regional Development...
GA ID:          GA523941
Recipient Name: Easyweb Digital Pty Ltd
Recipient ABN:  79 145 583 099
Value (AUD):    5341639.0
Publish Date:   2026-01-05
```

---

## Open Question: VALUE — Cumulative or Per-Grant?

**This is the critical unknown before implementation.**

In AusTender, the API returns a cumulative contract value across all amendments — the actual value per amendment must be scraped from the detail page (`/Cn/Show/{uuid}`). That scraping step is the most complex part of the AusTender pipeline.

For GrantConnect, we don't yet know if `Value (AUD)` is:

- **Per-grant (ideal):** The value of this specific grant award as published — no additional scraping needed
- **Cumulative (pain):** The total value across all versions/amendments — would need to scrape the detail page (`/Ga/Show/{uuid}`) for the per-version value, similar to AusTender

**How to resolve:** Compare a known amended grant (one with a `-V2` or later GA ID in the Advanced Search) against what appears in `GaPublishedDownload` for its original and amendment publish dates. If the value changes between versions, it's per-version (good). If it's always the running total, it's cumulative (needs scraping).

Also check: does `GaPublishedDownload` ever return versioned IDs (e.g. `GA484157-V1`)? In the sample (3 rows for 5-Jan-2026), all IDs were bare with no suffix. The Advanced Search with `LastedVariation=True` showed versioned suffixes. This suggests the Published report may only ever show original awards, not amendments — in which case the value question may not arise.

**Until resolved:** Build the pipeline treating Value as per-grant. Flag for verification during testing against known amended grants.

---

## Domain Model Mapping

| Grant concept | App model |
|---------------|-----------|
| Granting agency | `Group` (giver) |
| Recipient | `Group` (taker) — treat all as Group initially |
| Grant award (per publish date) | `IndividualTransaction` |
| Rollup per agency→recipient per FY | `Transfer` |
| GA ID | `IndividualTransaction.external_id` |
| Value (AUD) × 100 | `IndividualTransaction.amount` (integer cents) |

### New enum values needed

- `Transfer.transfer_type`: add `'government_grants'`
- `IndividualTransaction.transaction_type`: add `'government_grant'`

### Transfer effective_date

Use `Dates::FinancialYear.new(publish_date).last_day` — consistent with AusTender.

### ABN handling

- Clean ABN: strip spaces and non-digits (same as AusTender's business number cleaning)
- `"ABN Exempt"` → treat as nil ABN, create Group by name only
- `nil` ABN → same as above
- Valid ABN → pass to `Groups::RecordGroup` which will match existing Group or create + trigger `AbnLookupJob`

### Recipient as Person vs Group

Treat all recipients as `Group` initially. The existing `Groups::RecordGroup` handles name-only and ABN-first matching. Revisit if individual-person grants become relevant (arts grants, fellowships, etc.).

### Aggregate grants

`Aggregate: Y` rows represent a single XLSX row covering N individual awards (to protect recipient privacy, typically). Options:
- **Skip for now** — aggregate rows have reduced transparency value and no individual recipient
- **Ingest as-is** — record the aggregated amount against a group named something like "Aggregated Recipients"

Recommendation: skip aggregate grants in v1 (`next if row['Aggregate'] == 'Y'`), revisit later.

### Confidential grants

`Confidentiality - Contract: Y` rows have redacted recipient details (name shown as `n/a`, ABN as `ABN Exempt`). These are valid but low-value for transparency. Ingest as-is — the agency (giver) is still recorded, amount is real.

---

## Proposed Pipeline Architecture

### Jobs (Sidekiq)

```
IngestGrantsByDateJob            # daily: previous day's publish date
  → AuGrants::GrantsDownloader   # two-step GET → save XLSX to tmp/
  → AuGrants::XlsxParser         # roo: skip rows 1–23, yield row hashes
  → IngestSingleGrantJob (×N)    # one per row, queued async
  → (delete tmp XLSX)

BackfillGrantsMasterJob          # monthly + manual trigger
  # queues IngestGrantsByDateJob for each day of target month
  # checks queue depth before proceeding (mirrors BackfillContractsMasterJob)
```

### Services

```
AuGrants::GrantsDownloader
  - GET GaPublishedShow (capture Set-Cookie)
  - GET GaPublishedDownload (send cookie) → binary XLSX
  - Save to tmp/grants_{date}.xlsx
  - Return file path

AuGrants::XlsxParser
  - Roo::Excelx.new(path)
  - Skip rows 1–23 (header is row 23, data from row 24)
  - Yield each row as hash keyed by column name
  - Delete tmp file after iteration

AuGrants::RecordIndividualGrant  # mirrors AusTender::RecordIndividualTransaction
  - Dedup: IndividualTransaction.exists?(external_id: ga_id) → return if exists
  - Skip if aggregate (Aggregate == 'Y') — v1
  - RecordGroup for agency (giver) — name only
  - RecordGroup for recipient (taker) — ABN if present, else name only
  - Transfer.find_or_create_by!(giver, taker, effective_date, transfer_type: 'government_grants')
  - IndividualTransaction.create!(...)
  - RefreshSingleTransferAmountJob.perform_in(5.minutes, transfer.id)
```

### Rate limiting / resilience

Unknown whether GrantConnect throttles repeated requests — not tested. AusTender does (429 responses trigger the circuit breaker + Crawlbase fallback). As a precaution, `IngestSingleGrantJob` should mirror `IngestSingleContractJob`'s retry strategy: Sidekiq exponential backoff on 429/5xx, with a cap on retries. If throttling proves to be a real problem, add a circuit breaker similar to `Circuit::AusTenderScraperSwitch`.

### `evidence` URL

`IndividualTransaction.evidence` should point to the source record. Use the grant detail page:
```
https://www.grants.gov.au/Ga/Show/{GA_ID}
```
e.g. `https://www.grants.gov.au/Ga/Show/GA523941`. This gives a direct link to the published grant award, consistent with AusTender's contract-level evidence URLs.

### `fine_grained_transaction_category`

The XLSX `Category` column (e.g. `"Aged Care"`, `"Legal Services"`, `"Broadcasting and Telecommunications"`) maps naturally to `FineGrainedTransactionCategory`. In v1, leave this nil and treat it as a future enhancement — populate once a category seeding strategy is agreed (either auto-create from XLSX values or map to a pre-seeded list).

### Key differences from AusTender

| AusTender | Grants |
|-----------|--------|
| Fetches by contract modification date | Fetches by publish date |
| Two-step: API list → individual contract fetch | One-step: single XLSX contains all data |
| Scrapes detail page for amount + category | Amount in XLSX; no scrape needed (pending VALUE resolution) |
| Circuit breaker for scraper | No scraping in v1 — simpler |
| No ABN in API; relies on supplier field | Recipient ABN in XLSX directly |
| Amount from web scrape (not cumulative API value) | Amount from XLSX (per-grant — to be verified) |
| `transaction_type: 'government_contract'` | `transaction_type: 'government_grant'` |
| Amount stored as integer (cents) from web scrape | Convert `Value (AUD)` float × 100 → integer cents |

---

## Implementation Order

1. **Resolve VALUE question** — manually inspect an amended grant before writing any amount logic
2. Migrations: add `government_grants` to Transfer `transfer_type` enum; add `government_grant` to IndividualTransaction `transaction_type` enum
3. `AuGrants::GrantsDownloader` service (two-step cookie + download)
4. `AuGrants::XlsxParser` service (roo, row 24+ data)
5. `AuGrants::RecordIndividualGrant` service
6. `IngestSingleGrantJob`
7. `IngestGrantsByDateJob` (daily)
8. `BackfillGrantsMasterJob` (monthly + manual trigger for historical backfill)
9. Flipper flag to gate rollout, admin trigger for manual backfill
10. (Later) Detail page scraping for VALUE if needed
11. (Later) ARC grants as secondary source (separate pipeline, different model — lead investigator is a Person)

---

## Open Questions

1. **VALUE cumulative or per-grant?** — resolve before writing amount logic (see above)
2. **Does `GaPublishedDownload` ever return versioned GA IDs (`-V1`, `-V2`)?** — observed bare IDs only in the sample; needs confirmation across busier dates
3. **How far back to backfill?** — data exists from Dec 2017. At ~13K rows/month × 8.5 years ≈ 1.3M rows. Consider starting from a more recent year (e.g. FY2021) and expanding
4. **Aggregate grants** — skip in v1 or ingest with a placeholder recipient?
5. **Agency ABN** — the XLSX has no agency ABN column. Agencies are government departments and unlikely to need ABN matching, but worth noting. Use name-only matching for givers.
6. **`GaPublishedDownload` vs `GaAdvancedSearchDownload`** — confirm the Published endpoint is strictly superior (has ABN, richer fields) and retire the Advanced Search URL from the plan
