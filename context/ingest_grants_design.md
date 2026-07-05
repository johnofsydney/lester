# Government Grants Ingestion — Design Document

## Goal

Ingest Australian Commonwealth awarded grants from GrantConnect into the existing Transfer/IndividualTransaction model, mirroring the AusTender contracts pipeline.

---

## Data Source: GrantConnect

**Site:** https://www.grants.gov.au  
**Coverage:** All Commonwealth grant awards, mandatory reporting since 31 Dec 2017.

### Public XLSX Download (no auth required)

The search page embeds a download link that returns XLSX directly:

```
GET https://www.grants.gov.au/Search/GaAdvancedSearchDownload
  ?Page=1
  &ItemsPerPage=0
  &SearchFrom=AdvancedSearch
  &Type=Ga
  &AgencyStatus=0
  &KeywordTypeSearch=AllWord
  &DateType=Publish%20Date
  &DateStart=01-Jul-2025
  &DateEnd=01-Aug-2025
  &LastedVariation=True
  &OrderBy=Relevance
```

- Response: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- Content-Disposition: `attachment; filename=GrantConnect-Advanced-Search_<timestamp>.xlsx`
- No session/cookies required — plain GET with a browser User-Agent header works
- `DateType=Publish Date` with `DateStart`/`DateEnd` is the date filter
- `LastedVariation=True` returns only the latest version of each amended grant (important — avoids duplicate older versions)

The discovery path: `GaAdvancedSearch` (HTML) has a link to `GaAdvancedSearchDownload` (XLSX).

### XLSX Structure

- Single sheet: `GrantConnect-Advanced-Search`
- Rows 1–18: metadata/criteria summary (skip)
- Row 19: column headers
- Row 20+: data rows (~12,988 rows for one month)

**Columns (row 19):**

| Col | Field | Notes |
|-----|-------|-------|
| 1 | GA ID | Unique grant award ID. Versioned: `GA484157`, `GA484157-V1`, `GA484157-V2` |
| 2 | Grant Activity | Program/scheme name |
| 3 | Agency | Granting department → **giver** |
| 4 | Publish Date | Date grant was published |
| 5 | Category | Grant category (Aged Care, Child Care, Trade, etc.) |
| 6 | Start Date | Grant term start |
| 7 | End Date | Grant term end |
| 8 | Value (AUD) | Amount as decimal |
| 9 | GO ID | Grant Opportunity ID (links to the original opportunity) |
| 10 | Recipient Name | Organisation or person name → **taker** |
| 11 | One-off/Ad hoc | Yes/No |
| 12 | Aggregate Grant Award | Yes/No |
| 13 | Aggregate Reason | Text if aggregated |
| 14 | Number of Awards Aggregated | Integer |
| 15 | Last Updated | Timestamp string |

**No ABN column** in the public download (see ABN strategy below).

### Detail Page

Each grant has a detail view at:  
`https://www.grants.gov.au/Ga/Show/{UUID}`  
This likely contains ABN — worth checking once the basic pipeline works.

### Versioned GA IDs (Amendments)

GA IDs can have version suffixes: `GA484157`, `GA484157-V1`, `GA484157-V2`.  
Same pattern as AusTender contract amendments. The full versioned ID (e.g. `GA484157-V2`) is the unique key per award revision.

`LastedVariation=True` in the download URL means the XLSX only includes the **latest** version per grant, not the full amendment history. This simplifies ingestion but means older versions aren't captured.

---

## ABN Strategy

The public XLSX has recipient name only — no ABN column. Options:

1. **ABN Lookup enrichment (immediate):** The existing `AbnLookupJob` fires when a Group is created without ABN, looking up by name. This will cover most recipients automatically.

2. **Detail page scraping (`/Ga/Show/{UUID}`):** The detail page likely has ABN. Could scrape on create, similar to AusTender's `ScrapeSingleContractAmendment`. UUID is not in the XLSX but could be retrieved via a separate request.

3. **Data Hub (registered user, free):** GrantConnect's `Reporting > Data Hub > Awards` section offers CSV/Excel exports that reportedly include ABN. Requires a free account. May expose a POST endpoint we can call with session cookies — worth investigating after the basic pipeline works. This is probably the ABN-enriched spreadsheet recalled from prior research.

Between Dec 2017 and Jun 2021: ~103,561 awards had ABN recorded; ~4.5% were ABN-exempt or aggregate.

**Recommended starting approach:** Build pipeline without ABN; rely on `AbnLookupJob` for enrichment.

---

## ARC Grants (Secondary Source)

The Australian Research Council has a separate public REST API:

```
GET https://dataportal.arc.gov.au/NCGP/API/grants?page[number]=1&page[size]=1000
```

- Public, no auth, JSON API spec
- Covers research grants only (academic/university funding)
- Fields: grant code, scheme, lead investigator, administering org, funding amounts, status
- Lower political-transparency value than GrantConnect — consider later

---

## Domain Model Mapping

| Grant concept | App model |
|---------------|-----------|
| Granting agency | `Group` (giver) |
| Recipient | `Group` (taker) — treat all as Group initially |
| Grant award (latest version) | `IndividualTransaction` |
| Rollup per agency→recipient per FY | `Transfer` |
| GA ID (full versioned) | `IndividualTransaction.external_id` |

### New enum values needed

- `Transfer.transfer_type`: add `'government_grants'`
- `IndividualTransaction.transaction_type`: add `'government_grant'`

### Transfer date

Use `Dates::FinancialYear.new(publish_date).last_day` — consistent with AusTender's effective_date approach.

### Recipient as Person vs Group

In practice, the vast majority of politically interesting grants go to organisations. Treat all recipients as `Group` initially. The existing `Groups::RecordGroup` service handles name-only creation (no ABN) fine. Revisit if individual-person grants become relevant.

---

## Proposed Pipeline Architecture

Mirrors the AusTender pipeline closely.

### Jobs (Sidekiq)

```
IngestGrantsByDateJob          # daily: fetches previous day's publish_date range
  → GrantsDownloader           # GET GaAdvancedSearchDownload → save XLSX
  → GrantsXlsxParser           # roo: skip 18 header rows, yield row hashes
  → IngestSingleGrantJob (×N)  # one per row, queued async

BackfillGrantsMasterJob        # monthly: queues IngestGrantsByDateJob for each day of prev month
```

### Services

```
GrantsDownloader
  - GET request with date params + User-Agent header
  - Save binary to tmp/grants_{date}.xlsx
  - Return file path

GrantsXlsxParser
  - Roo::Excelx.new(path)
  - Skip rows 1–19 (header is row 19, data starts row 20)
  - Yield row hash keyed by column name
  - Delete tmp file after

RecordIndividualGrant          # mirrors AusTender::RecordIndividualTransaction
  - Dedup check: IndividualTransaction.exists?(external_id: ga_id)
  - RecordGroup for agency (giver) — name only initially
  - RecordGroup for recipient (taker) — name only, ABN lookup fires async
  - Transfer.find_or_create_by!(giver, taker, effective_date, transfer_type: 'government_grants')
  - IndividualTransaction.create(...)
  - RefreshSingleTransferAmountJob (5 min delay)
```

### Key differences from AusTender

| AusTender | Grants |
|-----------|--------|
| Fetches by contract modification date | Fetches by publish date |
| Scrapes detail page for amount + category | Amount is in XLSX; no scrape needed initially |
| Circuit breaker for scraper (429 handling) | No scraping needed initially — simpler |
| `IndividualTransaction.transaction_type: 'government_contract'` | `'government_grant'` |
| Amount in cents (integer) | Amount in AUD decimal — convert to cents on ingest |

---

## Open Questions

1. **`LastedVariation=True`** — does this mean we miss intermediate versions? Or is that fine since we only want current state? Confirm intent.
2. **Amount units** — XLSX shows decimal AUD (e.g. `76452.81`). Transfer.amount is integer (cents). Need to confirm multiply by 100.
3. **Data Hub ABN export** — can we get a session-authenticated POST endpoint after registering? Investigate after v1.
4. **Aggregate grants** — `Aggregate Grant Award: Yes` rows have a single row representing N awards. How should these be handled? Skip initially, or ingest as-is?
5. **`LastedVariation=False`** — would give the full amendment history. Do we want that?
6. **Date range for backfill** — how far back to go? Data exists from Dec 2017.
7. **Volume** — ~13K rows/month × ~8.5 years of history = ~1.3M rows total for full backfill. Sidekiq queue strategy needed.

---

## Implementation Order

1. Migrations: add `government_grants` to Transfer enum, `government_grant` to IndividualTransaction enum
2. `GrantsDownloader` service
3. `GrantsXlsxParser` service  
4. `RecordIndividualGrant` service
5. `IngestSingleGrantJob`
6. `IngestGrantsByDateJob` (daily)
7. `BackfillGrantsMasterJob` (monthly + manual trigger for historical backfill)
8. Admin UI / Flipper flag to gate rollout
9. (Later) Data Hub ABN enrichment
10. (Later) ARC grants as secondary source
