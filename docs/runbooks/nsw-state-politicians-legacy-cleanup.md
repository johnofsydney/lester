# NSW state politicians — legacy import cleanup

Manual pre-step required before [docs/plans/0011](../plans/0011-ingest-nsw-state-politicians-design.md)'s Ingest work can land real data. Mirrors the Federal politicians cleanup (`rake lester:cleanup_legacy_politician_memberships`, see [docs/plans/0004](../plans/0004-ingest-federal-politicians-design.md)'s "Manual pre-step" section), with one addition specific to this case — see below.

## What's being cleaned up

`Group.find(3740)` — "nsw parliament" — currently holds **512 Memberships** from the one-time copy/paste import described in [issue #248](https://github.com/johnofsydney/lester/issues/248): unreliable, not repeatable, no `evidence`, no dates. This needs to be gone before the new `pastvtr`-sourced Ingest work runs, for the same reason the Federal Branch/Parliament cleanup preceded OpenAustralia Interpretation — the new work assumes a clean slate for this Group, no reconciliation-with-legacy-data logic.

## How the Federal precedent worked, and where this differs

`rake lester:cleanup_legacy_politician_memberships` (federal) deletes `Membership`/`Position` rows for `Group.federal_parliament` and each Federal Branch party Group — it does **not** delete any `Person` records, just their memberships in those groups. That was the right call there because federal politicians are also touched by many other data sources (AEC donations, ACNC, lobbying register) — a Person losing their Federal Parliament Membership is very unlikely to be an orphan.

**Decided: NSW state politicians cleanup goes one step further** — after deleting `Membership`/`Position` rows for `Group.find(3740)`, also delete any `Person` whose **only** Membership (across the whole DB, not just this Group) was the one just removed. Unlike federal politicians, this legacy import was a standalone copy/paste job — a state MP with no other data source touching them (no donations, no other Group Membership, nothing) is very plausibly a person that exists in this DB *only* because of this one bad import, and deleting the Membership alone would leave a dangling, contentless Person record with no path back to real data.

**This must run in the correct order**: delete Positions → delete Memberships → *then* identify and delete now-orphaned People (a Person with zero remaining Memberships, checked after the Membership deletion above, not before — checking "only membership is to Group 3740" before deleting would be equivalent but more fragile to get right than "has zero memberships left" after).

## Sketch (mirrors `cleanup_legacy_politician_memberships`'s DRY_RUN shape — not yet implemented)

```ruby
task cleanup_legacy_nsw_state_politicians: :environment do
  dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'true'))
  group_id = 3740 # Group.find(3740) -- "nsw parliament"

  membership_ids = Membership.where(group_id:).pluck(:id)
  person_ids = Membership.where(id: membership_ids, member_type: 'Person').pluck(:member_id)
  position_count = Position.where(membership_id: membership_ids).count

  puts "DRY_RUN=#{dry_run}"
  puts "Group ##{group_id}: #{membership_ids.size} memberships, #{position_count} positions#{dry_run ? ' (would delete)' : ''}"

  if dry_run
    orphans_preview = Person.where(id: person_ids)
                            .where.not(id: Membership.where(member_type: 'Person').where.not(id: membership_ids).select(:member_id))
    puts "#{orphans_preview.count} people would become orphaned (would delete)."
    puts 'Run with DRY_RUN=false to apply changes.'
    next
  end

  positions_deleted = Position.where(membership_id: membership_ids).delete_all
  memberships_deleted = Membership.where(id: membership_ids).delete_all

  orphaned_people = Person.where(id: person_ids)
                          .where.not(id: Membership.where(member_type: 'Person').select(:member_id))
  people_deleted = orphaned_people.count
  orphaned_people.destroy_all # not delete_all -- runs Person's own dependent: :destroy associations cleanly

  puts "Deleted #{memberships_deleted} memberships, #{positions_deleted} positions, #{people_deleted} now-orphaned people."
end
```

`destroy_all` (not `delete_all`) for the People pass specifically, unlike the Membership/Position deletes above — a `Person` has its own `dependent: :destroy` associations (trading names, external identifiers, etc. — see `app/models/person.rb`) that need cleaning up properly, not left as orphaned rows of their own.

## Not yet decided

- Whether this ships as its own rake task (mirroring the federal one) or as an extension of a shared "legacy politician cleanup" task — implementation detail, not scoped here.
- Confirm no other subtle dependency exists on these 512 legacy Memberships before running for real (e.g. cached graph data referencing them) — run `DRY_RUN=true` first and eyeball the counts against expectations (~93 electorates worth of MPs, not 512 — worth understanding the gap before deleting, in case some of those 512 are legitimate multi-term duplicates or unrelated data, not all legacy-import noise).
