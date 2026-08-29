**Status: fixed (2026-08-29).**

# `Membership#overlapping` mishandles NULL start/end dates on `self`

**File:** `app/models/membership.rb:43-51`

```ruby
def overlapping
  base = Membership.where.not(id: self.id)
                   .where('end_date IS NULL OR end_date >= ?', self.start_date)
                   .where('start_date IS NULL OR start_date <= ?', self.end_date)

  base.where(group_id: self.group.id)
      .or(base.where(member_id: self.member.id))
end
```

**Domain rule:** a Membership with a `NULL` `start_date` and/or `end_date` is open-ended and
should overlap with everyone in the group for that open side (e.g. `NULL` `start_date` = "since
forever," `NULL` `end_date` = "still ongoing" — a fully-`NULL` membership overlaps everyone in the
group).

**Bug:** the query only handles `NULL` correctly on the *other* row (`end_date IS NULL OR ...`,
`start_date IS NULL OR ...`). If `self.start_date` or `self.end_date` is `NULL`, the bound params
(`self.start_date`, `self.end_date`) are themselves `NULL`, so `end_date >= NULL` / `start_date <=
NULL` evaluate to SQL `NULL` (falsy) for every row — the opposite of the intended "overlaps
everyone" behaviour. An open-ended membership calling `.overlapping` would incorrectly match
nothing on that side, rather than matching everyone.

**Also worth clarifying:** the `.or` combines "other memberships in the same group" with "other
memberships by the same member" — two different questions (peers in the group you're checking, vs.
this member's other unrelated stints elsewhere). Confirm whether the second branch is intentional.

**Status:** identified during the graph-traversal design discussion
([[large-groups-should-terminate-not-exclude]]); this method is currently dead code (called from
the shelved `BuildQueue` overlap branch, not the live path — see
`docs/backlog/dead-code-build-queue-can-add-to-queue.md`), so not urgent, but should be fixed
before any future overlap-aware traversal work relies on it.

**Fix:** guard each bound — treat `self.start_date.nil?`/`self.end_date.nil?` as "matches
everyone" on that side, symmetric with how the other row's NULLs are already handled.
