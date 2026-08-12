# Lobbyist duplicate-people: investigation, idempotency fix, and cleanup plan

## Context

Issue #234 ("Lobbyists - duplicate people") and a direct visual inspection of the live Lobbyists tag group (`https://join-the-dots.info/groups/124509`) confirm the same thing: most people on that page are listed two or three times. This isn't a display bug — the duplicates resolve to genuinely different `Person` database rows with identical names (e.g. "ADAM Benson" → `/people/1174` **and** `/people/238365`). This inflates the group's stats (1635 "People in Group", 462 "Connected Groups"), damages trust in a civic-transparency tool whose whole value proposition is data integrity, and will keep getting worse every time the biannual lobbyist ingest job runs.

This document covers: (1) root cause, (2) how to make lobbyist ingestion idempotent going forward, (3) how to safely merge the existing duplicates.

**On where this doc lives:** the repo has an established (if informally documented) convention of putting design/investigation docs in `context/YYYY-MM-DD-slug.md` — there's no ticket system, so the date-prefixed filename is the ordering/discoverability mechanism. It isn't written down in `CLAUDE.md` or `docs/agents/domain.md` (which explicitly says to proceed silently if convention docs don't exist), but it's the real precedent set by other files in this directory.

---

## Root cause

Two independent findings, confirmed via direct code reads and `git log`/`git show` (not just live-site inspection):

### 1. Two separate ingestion events created two full generations of Person records

- **Old generation** (Person IDs ~1174–1186, contiguous): commit `ae21b40e` ("made one csv for lobbyists and one ingester method", 2024-11-05) added `csv_data/lobbyists_2024-11-04.csv` (columns: `person,title,company`) as a one-off manual import, run via the commented-out `lib/tasks/add_records.rake` block (`FileIngestor.lobbyists_upload(file)` / `FileIngestor#general_upload` — the exact method that ran has since been refactored/renamed, but `general_upload`'s expected columns line up with this CSV's shape). This called `People::RecordPerson.call(row['person'])` — plain name, no external ID.
- **New generation** (Person IDs ~238364–238376+, contiguous, same relative row order as the old range): the current automated pipeline, `AuLobbyists::CsvImporter#import_lobbyist_people` → `AuLobbyists::ImportLobbyistsPeopleRowJob`, downloading fresh from the AGD API on the biannual cron. This *also* calls `People::RecordPerson.call(person_name)` — plain name, no external ID.

Both paths rely solely on `Person.find_by(name:)` for matching (no external identifier is registered for lobbyists — `ExternalIdentifier::SOURCES = %w[aec acnc open_australia]` — and unlike `Group`, `Person`'s plain-name path has no `trading_names` fallback). Two structurally separate code paths, months/years apart, pulling from two different data exports of the same real-world register, is exactly the kind of gap where whitespace/capitalization/punctuation drift between the two name strings causes every single row to miss the exact-match check on the second run and get created as a brand-new `Person` — explaining both the *volume* (near-total duplication across the group) and the *clean two-generation ID clustering* (each ingestion event created its own contiguous block in one run).

**Not yet verified** (no production DB access at the time of writing): the exact byte-level difference between a duplicate pair's two `name` values. Before executing the merge (below), do a quick production console check: `Person.where(id: [1174, 238365]).pluck(:id, :name)` to confirm they really are byte-identical after normalization (they should be, given `UPPER(name)` grouping is used to find pairs) or spot a subtler mismatch.

### 2. Two compounding structural weaknesses

- **`people.name` uniqueness was deliberately removed.** Commit `7fe3023b` ("remove name constrains, validation and force downcasing of names", 2026-03-30) dropped `validates :name, uniqueness:` on `Person` *and* the DB unique index `index_people_on_lower_name`, in favour of `trading_names`-based disambiguation — introduced in the same window. **`Group` got the equivalent trading-name fallback in `Groups::RecordGroup`; `Person` never did.** So today, nothing in the write path or the DB stops two `Person` rows sharing a name.
- **A live TOCTOU bug in the shared advisory-lock helper**, confirmed by reading `app/services/concerns/record/saving_helpers.rb`:
  ```ruby
  def save_inside_advisory_lock!(entity)
    entity.class.transaction do
      lock_id = Zlib.crc32(name).to_i
      entity.class.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")
      entity.save!   # no re-check for an existing record with this name after acquiring the lock
    end
    entity
  end
  ```
  `People::Record::RecordPersonWithName#call` never re-queries `Person.find_by(name:)` after acquiring the lock. Two concurrent Sidekiq jobs that both miss the outer `find_by` (in `People::RecordPerson#call`) will both proceed to create — the lock only serializes the writes, it doesn't prevent the second one. This affects every caller of `People::RecordPerson`'s plain-name branch (donations, general file ingest, lobbyists), not just lobbyists, and is a smaller contributing factor alongside the two-generation event above.

Secondary/cosmetic factor: `Group#people` / `#nodes` (`app/models/group.rb`) has no `.distinct`, so even a single Person with duplicate `Membership` rows would double-count in listings — not the primary cause here (the IDs are genuinely distinct people rows), but worth knowing since the Membership fix below touches this same code path.

---

## Part 1 — Idempotent ingestion fix

Ship independently, in this order:

1. **Fix the TOCTOU bug** in `app/services/concerns/record/saving_helpers.rb` — re-check `entity.class.find_by(name: entity.name)` *inside* the lock, before `save!`, and return the existing record if found. Behavior-preserving for every existing caller except the race case (today a silent bug). Add a spec exercising two concurrent calls for the same name.

2. **Add a `trading_names` fallback to `People::RecordPerson`'s plain-name branch** (`app/services/people/record_person.rb`), mirroring `Groups::RecordGroup`'s existing trading-name branches (find-by-trading-name, raise/log on ambiguous multi-match). Purely additive — only engages when the exact-name match already fails. This is the general-purpose resilience Person has been missing since the March 2026 uniqueness removal, and it means any alias recorded as a trading name during the cleanup below becomes a permanent future-proof alias.

3. **Add `lobbyists` as a scoped external-identifier source**, using a synthetic ID since the AGD register has no native per-lobbyist ID:
   ```ruby
   lobbyist_id = Digest::SHA256.hexdigest("#{cleaned_name}|#{lobbyist_abn}")
   ```
   Add `lobbyists` to `ExternalIdentifier::SOURCES`, add `lobbyist_id`/`lobbyist_id=` to `ExternalIdentifiable`, thread a `lobbyist_id:` kwarg through `People::RecordPerson` and `AuLobbyists::ImportLobbyistsPeopleRowJob`. **This must ship last, after Part 2's cleanup has run** — `Entity::RecordEntityWithExternalId`'s `find_sole_entity_by_name_and_append_external_id` bails out (and falls through to creating a *third* duplicate) if more than one Person still shares the name at attach-time. Verify via `Person.only_in_lobbyists.group(:name).having('count(*) > 1').count` returning ~0 before enabling this.

4. **Make the two `Membership` check-then-act blocks atomic** in `AuLobbyists::ImportLobbyistsPeopleRowJob` — replace `Membership.find_by(...) || Membership.create!(...)` with `Membership.find_or_create_by!(...)`. No DB unique index here: `Membership` legitimately allows repeat tenures for the same (member, group) pair (see the "Wayne Rooney" comment in `app/models/membership.rb`), so atomicity via `find_or_create_by!` is the correct-strength fix, not a constraint.

5. **(Optional/low priority)** a batch-level CSV hash watermark in `AuLobbyists::CsvImporter#import_lobbyist_people` to skip a no-op fan-out when the register hasn't changed since last run — an efficiency/observability nicety, not a correctness requirement, since steps 1–4 are what actually prevent duplicates.

---

## Part 2 — Merging the existing duplicates

1. **Fix `People::DeleteDuplicates`** (`app/services/people/delete_duplicates.rb`), which today only merges the first+last ID in a duplicate-name group (silently skipping anything in the middle for 3+ duplicates). Rewrite to fold all duplicates into one deterministic keeper (lowest ID = oldest record), with a `dry_run:` flag defaulting to `true`, following the existing `lester:dedupe_transfers_natural_key` rake-task convention (log every merge, review, then re-run for real). Apply the identical fix to `Groups::DeleteDuplicates` (same bug shape), as a small bundled fix.

2. **Scope the cleanup to lobbyist-only people first.** Do not run an unscoped merge across all `Person` rows — a same-name collision outside the lobbyist context (e.g. two unrelated people who happen to share a name, one an AEC donor and one a lobbyist) must not get auto-merged. Add a `Person.only_in_lobbyists` scope mirroring the existing `only_in_charities` pattern (member of the Lobbyists tag group, and every other membership is also within that same subgraph). Run the merge only against `Person.only_in_lobbyists`. Anyone excluded by that scope (a duplicate pair where one side also has unrelated memberships) goes to a manual-review list instead of being auto-merged.

3. **Add a Person-side admin merge action**, mirroring the existing `Admin::Groups#perform_merge` (`app/admin/groups.rb`, `app/views/admin/groups/merge_with.html.erb`) — needed both for the manual-review leftovers from step 2 and as a standing tool for future one-off duplicates a human spots (there's already `Admin::People::ExplodePerson` as the inverse operation; this fills the obvious gap).

4. **Fix cache invalidation after merge.** `Nodes::Merge#handle_refresh_job` only rebuilds the cache of the merged-into Person, not any Group whose membership set changed as a side effect — so without this fix, `/groups/124509` would keep showing stale duplicates for up to a week even after the DB is clean. After each merge, enqueue `Cache::BuildGroupCachedDataJob` for the Lobbyists tag group and each affected employer Group.

5. **Wrap it in a `maintenance_tasks` Task** (`app/tasks/maintenance/dedupe_lobbyist_people_task.rb`, `Maintenance::DedupeLobbyistPeopleTask`), run and monitored from the `/maintenance_tasks` admin UI rather than a rake task. `collection` is `Person.only_in_lobbyists`'s duplicate ids (excluding the lowest-id keeper per name); `process(duplicate)` re-derives the current keeper at call-time so it's safe to reprocess the same person if the task is interrupted/resumed. A `dry_run` Active Model attribute (default `true`, toggleable from the run-start form) replaces the rake task's `DRY_RUN` env var — run once with it on to eyeball the log output, then again with it off to apply.

### Rollout order

1. TOCTOU fix (1.1) — smallest, safest, ships alone first.
2. Fixed `DeleteDuplicates` + lobbyist-only scope + `Maintenance::DedupeLobbyistPeopleTask` (2.1, 2.2, 2.5) — start a run from `/maintenance_tasks` with `dry_run` on, eyeball the log output, then start a fresh run with `dry_run` off. This is the fix users will actually see reflected on the live page.
3. Cache rebuild (2.4) — bundled into the same rewrite; manually verify `/groups/124509` afterward.
4. Person admin merge UI (2.3) — any time after step 2, for manual-review leftovers.
5. `trading_names` fallback on `RecordPerson` (1.2) — after step 2, so it doesn't interact confusingly with still-duplicated data mid-cleanup.
6. `find_or_create_by!` for Memberships (1.4) — independent, any time.
7. `lobbyists` external-id source (1.3) — **last**, only after step 2's cleanup has actually run (see the `entities.many?` landmine above).
8. CSV batch watermark (1.5) — optional, lowest priority.

---

## Files changed

- `app/services/concerns/record/saving_helpers.rb` — TOCTOU fix
- `app/services/people/record_person.rb` — trading_names fallback, `lobbyist_id:` kwarg
- `app/models/external_identifier.rb`, `app/models/concerns/external_identifiable.rb` — `lobbyists` source
- `app/sidekiq/au_lobbyists/import_lobbyists_people_row_job.rb` — `find_or_create_by!`, pass `lobbyist_id:`
- `app/services/au_lobbyists/csv_importer.rb` — optional watermark
- `app/services/people/delete_duplicates.rb`, `app/services/groups/delete_duplicates.rb` — fix multi-duplicate bug
- `app/models/person.rb` — `only_in_lobbyists` scope
- `app/admin/people.rb`, `app/views/admin/people/merge_with.html.erb`, `config/routes.rb` — Person admin merge action
- `app/tasks/maintenance/dedupe_lobbyist_people_task.rb` — `Maintenance::DedupeLobbyistPeopleTask` (run from `/maintenance_tasks`)
- Specs alongside each changed service

## Verification

- `bundle exec rspec spec/services/people/ spec/services/concerns/ spec/services/au_lobbyists/` after each change.
- Before enabling step 1.3, confirm via Rails console: `Person.only_in_lobbyists.group(:name).having('count(*) > 1').count` is empty.
- After Part 2's `Maintenance::DedupeLobbyistPeopleTask` run completes with `dry_run` off, reload `https://join-the-dots.info/groups/124509` and confirm no duplicate names remain in the People list, and that "People in Group" / "Connected Groups" counts have dropped correspondingly.
- Spot-check a few individually merged people's pages (`/people/:id`) to confirm memberships, transfers, and trading names carried over correctly via `Nodes::Merge`.
