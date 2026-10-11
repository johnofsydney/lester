# Confirm the intent of `Membership#overlapping`'s `.or` branch

**File:** `app/models/membership.rb` (`#overlapping`)

**Context:** the method combines "other memberships in the same group" with "other memberships by
the same member" via `.or`. These answer two different questions — peers in the group being
checked, versus this member's own unrelated stints elsewhere. Flagged during the Capped-node
design work; the NULL-handling around it is fixed, but whether the second branch is intentional
was never confirmed. The method is still dead code (no live traversal caller), so this only
matters before any future overlap-aware Capping relies on it.

**Fix:** decide which question overlap-aware traversal actually needs answered, and either keep
the `.or` deliberately (with a spec pinning both branches) or split the method in two.
