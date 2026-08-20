# Polymorphic associations have no DB-level constraints

`Transfer.giver/taker`, `Membership.member`, `ExternalIdentifier.owner` are all polymorphic with
no FK constraints at the DB level. Direct SQL inserts (migrations, scripts, psql) can create
orphaned references that AR will never catch.

This is a Rails limitation (polymorphic FKs are non-trivial), but it means any bulk operation that
bypasses AR is a data integrity risk.

**Mitigation:** document this explicitly; add a periodic integrity check job that scans for
orphaned polymorphic references.

**`Membership.member` — partially addressed (2026-08-20, #267/#268):** `Group` was missing
`dependent: :destroy` on the `member`-side of `Membership` (it only had it for the `group_id`
side; `Person` already had both). ActiveAdmin's default batch-destroy also bypassed the one guard
that existed, which is how a Group ended up destroyed with orphaned member-side `Membership` rows
still pointing at it, crashing `NodeMethods#best_group_memberships`. Fixed with
`Group#memberships_as_member` (the missing cascade) and a guard on the batch-destroy action, plus
`Maintenance::CleanupOrphanedMembershipsTask` (`/maintenance_tasks`) as an on-demand scan/cleanup
for `Membership.member` specifically.

Still open: the scan isn't periodic/automated (it's a manually-run maintenance task, not a
scheduled job), and `Transfer.giver/taker` and `ExternalIdentifier.owner` have the same structural
risk and no equivalent cascade/guard/cleanup at all.
