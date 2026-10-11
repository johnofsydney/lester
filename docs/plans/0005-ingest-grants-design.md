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
- **Requires a realistic browser `User-Agent`** (confirmed 2026-08-29) — Faraday's default UA, and even a bare `"Mozilla/5.0"`, get a 403. A full Chrome-style UA string works
- The show page sets **two** `Set-Cookie` headers (`UR_BCF` and `__RequestVerificationToken`) — both must be forwarded on the download request or it 403s. Faraday's Net::HTTP adapter merges multiple `Set-Cookie` response headers into one comma-joined string; forwarding that string verbatim as the `Cookie` header is invalid — each `name=value` pair (before its first `;`) must be extracted and re-joined with `; `
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

**Resolved (2026-08-25), refined (2026-09-13) after direct evidence — see "Amendment Detection & Handling" below:** `Value (AUD)` at any single row is a **cumulative snapshot as of that version**, not the true incremental value of that specific award or amendment — the same shape of problem AusTender has. For a grant that has never been amended, the row's value *is* the grant's true value, so the original v1 assumption ("no scraping needed") holds for the common case. But for an amended grant, the value changes across versions (proven: one real grant's value went `$3,294,711.20 → $3,039,418.80 → $3,294,711.20` — it decreased then increased, which is only possible if each row is a point-in-time snapshot, not a running total that only grows). Scraping is required to detect *which* grants have been amended and to recover the true original (pre-amendment) amount, which does not appear in either bulk export at all. See the new section below for the full mechanism.

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

### Confidential grants / redacted recipients

**Resolved (2026-08-25), corrected (2026-08-29) after a live run against real GrantConnect data:** `Confidentiality - Contract: Y` does **not** reliably indicate a redacted recipient — a real row observed in the `05-Jan-2026` publish date had `Confidentiality - Contract: Y` with a fully real `Recipient Name` and ABN. The actual redaction signal is `Recipient Name == "n/a"` (`Release#redacted_recipient?`). Recording redacted rows as-is would merge every one of them across every agency into a single `Group` named "n/a" (name-only matching in `Groups::RecordGroup`), falsely linking unrelated redacted recipients. **Skip rows where the recipient is redacted, in v1**, same treatment as aggregate rows (`return if release.aggregate? || release.redacted_recipient?`). Do not key this off the confidentiality flag — it skips real, attributable grants. Revisit later if a way to keep redacted rows distinct (e.g. per-agency placeholder groups) is wanted.

---

## Amendment Detection & Handling

**Added 2026-09-13, based on direct evidence pulled from real GrantConnect data (a full month, Jan 2026, 6,769 clean rows).** This mirrors the AusTender pipeline's central problem — the bulk-download value is a cumulative snapshot, not a per-award amount — and the fix is the same shape: the web show page is the ultimate source of truth, and per-amendment amounts are reconstructed by diffing consecutive snapshots. This section supersedes the "per-grant, no scraping needed" resolution above for any grant that has been amended.

### Evidence

- Across a full clean month of `GaPublishedDownload` data, **no `GA ID` ever repeats, and no version suffix ever appears.** `GO ID` and `Internal Reference ID` also do not indicate amendments — both are shared by many unrelated recipients under the same funding round/program (e.g. one `GO ID` covering 8 different universities' ARC grants). **`GaPublishedDownload` cannot tell you a grant has been amended, at all.**
- `GaAdvancedSearchDownload` (queried without `LastedVariation=True`, across the same month) **does** carry version suffixes: `GA531362`, `GA531362-V1`; `GA528013`, `GA528013-V1`, `GA528013-V2`, etc. 52 of ~6,800 base GA IDs in the sample month had at least one variation.
- `Publish Date` is **identical across every version of a grant** — only a `Last Updated` timestamp (visible in `GaAdvancedSearchDownload`, not in `GaPublishedDownload`) changes when a grant is amended. Amendments were observed landing many months after the original publish date (a Jan-2026 grant amended as late as Sep-2026 in the sample).
- The base (no-suffix) row in both bulk exports **mirrors the current/latest value, not the original.** For `GA528013`: base row and `-V2` both show `$3,294,711.20`; `-V1` shows `$3,039,418.80` (an actual decrease, proving these are point-in-time snapshots, not a running total).
- The show page (`/Ga/Show/{guid}`, reachable via `Ga ID` → HTML `GaAdvancedSearch` page → `/Ga/Show/{guid}` link, no XLSX download involved) is the **only** place the true original (pre-amendment) value appears — it's not in either bulk export. For `GA528013` the show page reports `Value (AUD): $3,294,711.20` with `Original: $2,279,564.10`, and a `Variations:` list: `GA528013-V2 - Increase in Grant Funding (23-Jul-2026)`, `GA528013-V1 - Increase in Grant Funding and change to End Date (2-Jul-2026)`.
- The `Variations:` list gives a human-readable reason and date **per variation, but not a dollar amount** — so even the show page doesn't hand you each amendment's own value directly. That still has to be reconstructed by diffing.

### Mechanism (mirrors AusTender's amendment scraping)

1. **Cheaper detection than AusTender's "scrape every row":** AusTender's API gives no versioning signal at all, so every contract gets scraped. Here, `GaAdvancedSearchDownload` already reveals in bulk which base `GA ID`s have any `-V` siblings — so only that subset needs a show-page scrape, not every grant. Whether to source this via a periodic bulk `GaAdvancedSearchDownload` diff, or by checking each ingested grant's show page directly, is an implementation choice (see Open Questions below).
2. **GUID resolution:** the plain HTML `GaAdvancedSearch` results page (not the `...Download` XLSX endpoint) links directly to `/Ga/Show/{guid}` per result — a normal two-step scrape (search by `GaId=`, extract the GUID, fetch the show page), same shape as AusTender's contract-UUID resolution.
3. **Reconstructing per-version amounts:** order a grant's versions chronologically (`Original` from the show page, then each `-V<n>`'s cumulative value from the bulk export, ordered by `Last Updated` since `Publish Date` is frozen). Diff consecutive cumulative values to get each version's own incremental amount — `Original → V1` is the first amendment's value, `V1 → V2` the second, and so on. This is the same diffing AusTender already does for contract amendments.
4. **New polling requirement:** since amendments don't get a new `Publish Date`, our current daily-by-publish-date job structurally cannot discover them after the fact. Catching amendments going forward needs a re-check mechanism keyed on something other than publish date — closer to AusTender's "poll by contract-last-modified date" model than our current "poll by publish date, once" model. Whether GrantConnect's search supports filtering by `Last Updated` directly (as a `DateType` option, alongside the observed `Publish Date`/`Approval Date`/`Start Date`/`End Date`) is unconfirmed — needs checking against the search form's actual `DateType` dropdown options.

### Implication for scope

This is materially more work than the original "no scraping needed" v1 design assumed. The un-amended common case (no version suffix ever observed for that GA ID) still needs no scraping — the bulk export value is correct as-is. Only the amended subset needs the show-page/diffing treatment. Given only 52 of ~6,800 grants (~0.8%) had any amendment in the sample month, prioritise: ship the current no-scrape pipeline for the common case first (already done), then add amendment detection + reconciliation as a distinct, later phase — do not block the whole pipeline on solving amendment handling first.

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
  - Skip if confidential (Confidentiality - Contract == 'Y') — v1, avoids false-merging redacted "n/a" recipients
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

**Resolved (2026-08-25):** `IndividualTransaction.fine_grained_transaction_category` is a required (non-optional) association, so it cannot be left nil. Auto-create from the XLSX `Category` column, same as AusTender: `FineGrainedTransactionCategory.find_or_create_by!(name: release.category)`.

### Key differences from AusTender

| AusTender | Grants |
|-----------|--------|
| Fetches by contract modification date | Fetches by publish date |
| Two-step: API list → individual contract fetch | One-step: single XLSX contains all data |
| Scrapes detail page for amount + category, for every contract | Amount in XLSX is correct as-is for un-amended grants (the common case); detail-page scrape + diffing only needed for the ~0.8% of grants with a variation (see "Amendment Detection & Handling") |
| Circuit breaker for scraper | Scraping is a smaller, later-phase concern — only touches amended grants, not every row |
| No ABN in API; relies on supplier field | Recipient ABN in XLSX directly |
| Amount from web scrape (always, since API never gives per-amendment value) | Amount from XLSX directly for un-amended grants; web scrape + snapshot-diffing only for amended ones |
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
10. **(Later, separate phase) Amendment detection & reconciliation** — see "Amendment Detection & Handling": GUID resolution, show-page scrape, cumulative-snapshot diffing, and a new re-check polling mechanism (not keyed on publish date). Do not block the common-case pipeline on this.
11. (Later) ARC grants as secondary source (separate pipeline, different model — lead investigator is a Person)

---

## Open Questions

1. ~~**VALUE cumulative or per-grant?**~~ — refined 2026-09-13: per-grant for un-amended grants (the common case, correct as originally resolved); cumulative-snapshot-per-version for amended grants, requiring scrape + diff. See "Amendment Detection & Handling".
2. ~~**Does `GaPublishedDownload` ever return versioned GA IDs?**~~ — resolved 2026-09-13: no, never — confirmed across a full clean month (6,769 rows, zero version suffixes). Only `GaAdvancedSearchDownload` carries them.
3. **How far back to backfill?** — data exists from Dec 2017. At ~13K rows/month × 8.5 years ≈ 1.3M rows. Consider starting from a more recent year (e.g. FY2021) and expanding
4. **Aggregate grants** — skip in v1 or ingest with a placeholder recipient?
5. **Agency ABN** — the XLSX has no agency ABN column. Agencies are government departments and unlikely to need ABN matching, but worth noting. Use name-only matching for givers.
6. ~~**`GaPublishedDownload` vs `GaAdvancedSearchDownload`**~~ — resolved 2026-09-13: neither retires the other. `GaPublishedDownload` stays primary for the daily common-case ingest (richer fields, ABN). `GaAdvancedSearchDownload` is now known to be load-bearing for amendment detection (it's the only bulk source that carries version suffixes) — keep both.
7. **New (2026-09-13): does GrantConnect's search support filtering by `Last Updated`/amendment date?** Needed to build a re-check polling job that can discover amendments after the fact, since `Publish Date` never changes when a grant is amended. Check the search form's actual `DateType` dropdown options.
8. **New (2026-09-13): bulk-diff vs per-grant show-page check for amendment detection?** — either periodically re-pull `GaAdvancedSearchDownload` and diff against already-recorded external_ids for new `-V` siblings, or check each ingested grant's show page directly. Bulk-diff is likely cheaper (matches the AusTender-improvement noted above) but unverified against real polling volume.
9. ~~**A parsed blank/malformed row bug existed in `XlsxParser`**~~ — fixed 2026-09-13. Two distinct issues, both now covered by real-fixture specs (`spec/fixtures/au_grants/`): (a) `row&.any?` only filtered fully-`nil` rows, not all-empty-string rows; (b) more seriously, on a day with **zero published grants**, GrantConnect's XLSX contains a literal message row — `"There are no results that match your selection."` in the Agency column, everything else `nil` — which was passing through as a fake grant record (would have created a real `Group` named after that message string). Fixed by filtering on `GA ID` presence directly (a genuine row always has one; both bad-row shapes don't).
