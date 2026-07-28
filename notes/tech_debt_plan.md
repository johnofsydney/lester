# Tech Debt & Flaws — Prioritised Plan

Generated 2026-07-02. Supersedes `improvement_candidates.md` (which covers items 3, 5, 7, 8, 9 below in more detail).

---

## Phase 1 — Fix Before the Next Data Ingest

These are correctness bugs that silently corrupt or lose data.

### 1. `RecordTransfer` doesn't include `amount` in `find_or_create_by!`
**File:** `app/services/record_transfer.rb:22`

```ruby
Transfer.find_or_create_by!(giver:, taker:, effective_date:, transfer_type:, evidence:)
# amount is not here — so if the same transfer arrives with a revised amount, it's silently ignored
```

Two different amounts for the same transfer (e.g. an amended AEC disclosure) will return the first record unchanged. Cached aggregate totals will be wrong.

**Fix:** Include `amount:` in the `find_or_create_by!` call, or use `find_or_create_by!(...)` then `update!(amount:)` if found (depending on desired semantics — keep highest? keep latest?).

---

### 2. `RecordDonation` is dead and contains typos that would corrupt data if it were ever re-enabled
**File:** `app/services/record_donation.rb`

- `initialize` and `call` both start with bare `raise` — the class is completely non-functional.
- `person_or_group` has `return 'goup'` (typo, lines 55–56) — not 'group'. Would route matched records to an unknown branch.
- The regex logic is an older, narrower subset of `RecordPersonOrGroup` — it would misclassify donors.

**Fix:** Delete the file entirely. If the `person_or_group` regex logic needs to be compared with `RecordPersonOrGroup`, do it via git history, not a dead production file.

---

### 3. Sidekiq jobs call `.find(id)` with no `RecordNotFound` guard
**Files:**
- `app/sidekiq/cache/node_count_job.rb:13`
- `app/sidekiq/transfers/refresh_single_transfer_amount_job.rb:12`
- `app/sidekiq/acnc/ingest_single_charity_people_job.rb`
- `app/sidekiq/abn/update_group_names_job.rb`

If a record is deleted between enqueue and execution, Sidekiq retries forever (default 25 attempts over 21 days) then dead-letters the job.

**Fix:** Rescue `ActiveRecord::RecordNotFound` and return early:
```ruby
def perform(id)
  record = Person.find_by(id:)
  return unless record
  # ...
end
```

---

## Phase 2 — Data Integrity & Model Correctness

### 4. `Suggestion` model has no validations; controller uses `save` not `save!`
**Files:** `app/models/suggestion.rb`, `app/controllers/home_controller.rb:23`

The model is a single empty class body. The schema marks `headline` and `evidence` as NOT NULL, but there are no AR validations — so a bad form submit either hits a DB constraint error (ugly 500) or silently ignores the failure.

**Fix:** Add `validates :headline, :evidence, presence: true`. Change `save` to `save!` or check the result and render errors.

---

### 5. Transfer uniqueness validation doesn't match the actual DB constraint
**File:** `app/models/transfer.rb:11-14`

The AR `validates_uniqueness_of` and the `schema.rb` unique index don't cover the same columns. The validation gives a misleading error message and the real enforcement is a DB exception that surfaces as a 500.

**Fix:** Align the `validates_uniqueness_of` with the actual unique index columns so the validation catches conflicts before hitting the DB and produces a clean error.

---

### 6. Hardcoded tag IDs will raise `RecordNotFound` in any non-production DB
**File:** `app/models/group.rb:214-228`

```ruby
def self.charities_tag = Group.find(124_513)
```

These IDs only exist in the production DB. On a fresh dev DB or staging restore with a different sequence, every scope that calls these raises `RecordNotFound`. There's also no indication in code what these IDs mean.

**Fix:** Look up by name:
```ruby
def self.charities_tag = find_by!(name: 'charities', type: 'Tag')
```
Add seed data or a guard task. See `improvement_candidates.md` §3 for the full proposal.

---

### 7. `RecordPersonOrGroup` classifier has duplicate patterns, typos, and no debug mode
**File:** `app/services/record_person_or_group.rb`

- `regex_for_company_words_13` and `regex_for_company_words_14` are identical (dead pattern).
- `regex_for_specific_companies_1` and `regex_for_campaign_words_3` are identical.
- "Constitutional" is misspelled "Constituional" in two patterns — those names never match.
- `return 'goup'` typo (never returns a valid branch).
- No way to know which rule classified a given name.

Misclassification corrupts the entire donation dataset.

**Fix:** See `improvement_candidates.md` §1 for the full proposal.

---

## Phase 3 — Performance

### 8. N+1 in `NodeMethods#name_for_bar_graph` (runs on every cache build)
**File:** `app/models/concerns/node_methods.rb:116-125`

One `find` query per transfer counterparty. For large political parties (ALP, Liberals) with hundreds of counterparties this fires hundreds of individual queries per cache build.

**Fix:** Batch-load all counterparty names with two `pluck` queries and build a lookup hash before the transform. See `improvement_candidates.md` §2.

---

### 9. View count increment is not atomic
**Files:** `app/controllers/people_controller.rb:67-72`, `groups_controller.rb:97-102`, `transfers_controller.rb:62-67`

`record.increment(:views); record.save` is a read-then-write with no lock. Concurrent requests silently drop increments.

**Fix:** Replace with `record.increment!(:views)` (single SQL `UPDATE ... SET views = views + 1`) or `record.update_counters(views: 1)`.

---

## Phase 4 — Dead Code Cleanup

### 10. Dead code in `BuildQueue#can_add_to_queue?`
**File:** `app/services/build_queue.rb:37-79`

40+ lines of an alternative traversal algorithm after an early `return`. Comment says "leaving for later cherry picking" — that's what git is for.

**Fix:** Delete lines 37–79. Move the interesting bits to a comment in `CanAddToQueue` if they're worth preserving as reference.

---

### 11. `Person` model: duplicate `include`, dead `transfers` method, dead assignment
**File:** `app/models/person.rb`

- `include ExternalIdentifiable` appears twice (lines 6 and 14).
- `#transfers` is acknowledged dead ("always nil") — `incoming_transfers` / `outgoing_transfers` are the live paths.
- An `OpenStruct.new(...)` in `#first_degree_transfers` is evaluated but its return value is discarded.

**Fix:** Remove the duplicate include. Delete `#transfers`. Remove the dead `OpenStruct.new(...)` line.

---

### 12. `RecordDonation` (see item 2 above)

---

## Phase 5 — Test Coverage

### 13. Zero specs for any Sidekiq job
There are ~29 jobs across `app/sidekiq/` and zero corresponding specs. No regression protection for:
- All cache rebuild jobs
- All AusTender ingestion jobs
- All AuLobbyists jobs
- Transfer refresh jobs
- ABN jobs

**Fix:** Prioritise specs for the highest-risk jobs first: `BuildPersonCachedDataJob`, `BuildGroupCachedDataJob`, the AEC ingestion jobs. Use a real test DB (not mocks) — see project history on why mocked DB tests failed us.

---

### 14. No specs for `RecordTransfer` uniqueness or concurrent scenarios
**Fix:** Add a spec that calls `RecordTransfer.call` twice with identical args and asserts only one Transfer is created. Then add a test for the amount-mismatch case once item 1 above is resolved.

---

## Phase 6 — Architecture

### 15. Polymorphic associations have no DB-level constraints
`Transfer.giver/taker`, `Membership.member`, `ExternalIdentifier.owner` are all polymorphic with no FK constraints at the DB level. Direct SQL inserts (migrations, scripts, psql) can create orphaned references that AR will never catch.

This is a Rails limitation (polymorphic FKs are non-trivial), but it means any bulk operation that bypasses AR is a data integrity risk. **Mitigation:** document this explicitly; add a periodic integrity check job that scans for orphaned polymorphic references.

---

### 16. `set_external_identifier` in `ExternalIdentifiable` has a find-or-initialize race
**File:** `app/models/concerns/external_identifiable.rb:30-36`

`find_or_initialize_by` + `save!` can race under concurrent ingestion — two workers could both initialise the same record and one will fail on the unique constraint.

**Fix:** Use `find_or_create_by!` (which is safer under concurrency) or add `rescue ActiveRecord::RecordNotInvalid` and retry once.

---

## Summary Table

| # | Area | Severity | Effort |
|---|------|----------|--------|
| 1 | Transfer amount not in find_or_create | High | Small |
| 2 | RecordDonation dead + typos | High | Tiny (delete it) |
| 3 | Sidekiq .find without guard | High | Small |
| 4 | Suggestion validations missing | Medium | Tiny |
| 5 | Transfer uniqueness validation mismatch | Medium | Small |
| 6 | Hardcoded tag IDs | Medium | Small |
| 7 | RecordPersonOrGroup regex duplicates/typos | High | Medium |
| 8 | N+1 in name_for_bar_graph | Medium | Small |
| 9 | View count not atomic | Low | Tiny |
| 10 | BuildQueue dead code | Low | Tiny |
| 11 | Person model junk | Low | Tiny |
| 13 | No job specs | High | Large |
| 14 | No RecordTransfer specs | Medium | Small |
| 15 | Polymorphic no DB constraints | Low | Medium |
| 16 | set_external_identifier race | Low | Small |
