# NSW state politicians — legacy import cleanup

Manual pre-step required before [docs/plans/0011](../plans/0011-ingest-nsw-state-politicians-design.md)'s Ingest work can land real data. The federal politicians equivalent (`rake lester:cleanup_legacy_politician_memberships`, see [docs/plans/0004](../plans/0004-ingest-federal-politicians-design.md)'s "Manual pre-step" section) is console/rake-only; this one is a `maintenance_tasks` gem task, run from `/maintenance_tasks` — see [[feedback_maintenance_tasks_gem]] / the project owner's preference for post-deploy tasks to always go through that gem rather than plain rake, per John's request to promote this from an initial rake sketch.

## What's being cleaned up

`Group.nsw_parliament` ("nsw parliament", confirmed id 3740) — currently holds **512 Memberships** from the one-time copy/paste import described in [issue #248](https://github.com/johnofsydney/lester/issues/248): unreliable, not repeatable, no `evidence`, no dates. This needs to be gone before the new `pastvtr`-sourced Ingest work runs, for the same reason the Federal Branch/Parliament cleanup preceded OpenAustralia Interpretation — the new work assumes a clean slate for this Group, no reconciliation-with-legacy-data logic.

## How the Federal precedent worked, and where this differs

`rake lester:cleanup_legacy_politician_memberships` (federal) deletes `Membership`/`Position` rows for `Group.federal_parliament` and each Federal Branch party Group — it does **not** delete any `Person` records, just their memberships in those groups. That was the right call there because federal politicians are also touched by many other data sources (AEC donations, ACNC, lobbying register) — a Person losing their Federal Parliament Membership is very unlikely to be an orphan.

**Decided: NSW state politicians cleanup goes one step further** — after deleting a Membership (and its Positions, via cascade) in `Group.nsw_parliament`, also delete that Membership's Person if they're now left with zero Memberships anywhere in the DB. Unlike federal politicians, this legacy import was a standalone copy/paste job — a state MP with no other data source touching them (no donations, no other Group Membership, nothing) is very plausibly a person that exists in this DB *only* because of this one bad import, and deleting the Membership alone would leave a dangling, contentless Person record with no path back to real data.

## Implementation: `Maintenance::CleanupLegacyNswStatePoliticiansTask`

`app/tasks/maintenance/cleanup_legacy_nsw_state_politicians_task.rb`. Follows the same `MaintenanceTasks::Task` shape as `Maintenance::CleanupOrphanedMembershipsTask` / `Maintenance::DedupeLobbyistPeopleTask` — `attribute :dry_run, :boolean, default: true`, `collection` is `Membership.where(group: Group.nsw_parliament)`, `process(membership)` handles one Membership at a time.

**The orphan check happens per-Membership, immediately after that Membership is destroyed** — not as a separate whole-Group pass afterwards. This is what makes the task safely resumable across multiple job-iteration batches: checking "does this specific Person have zero Memberships left, right now" is correct regardless of what order or how many separate runs the rest of the collection gets processed in, unlike a fixed two-phase "delete everything, then scan for orphans" approach which would need to assume the whole collection finished in one pass.

`membership.destroy` (not `delete_all`) cascades to its Positions automatically (`Membership has_many :positions, dependent: :destroy`); `person.destroy` (not `delete`) similarly runs `Person`'s own `dependent: :destroy` associations (trading names, external identifiers, etc.) cleanly rather than leaving them as orphaned rows of their own.

Run from `/maintenance_tasks` with `dry_run: true` first (the default) to see counts before committing.

## Not yet decided

- Confirm no other subtle dependency exists on these 512 legacy Memberships before running for real (e.g. cached graph data referencing them) — run with `dry_run: true` first and eyeball the counts against expectations (~93 electorates worth of MPs, not 512 — worth understanding the gap before deleting, in case some of those 512 are legitimate multi-term duplicates or unrelated data, not all legacy-import noise).
