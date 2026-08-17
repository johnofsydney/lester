# Hardcoded tag IDs raise a cryptic `RecordNotFound` on a fresh/restored DB

**File:** `app/models/group.rb:214-228`

```ruby
def self.charities_tag = Group.find(124_513)
```

These IDs only exist in the production DB. On a fresh dev DB or a staging restore with a different
sequence, every scope that calls these raises a bare `ActiveRecord::RecordNotFound` with no
indication of what the ID means or how it was seeded.

**Note:** switching to `find_by!(name: ...)` is **not** the fix here — this project deliberately
prefers hardcoded DB IDs over name lookups, because the production DB is never recreated, IDs are
stable, and names are user-editable (a weaker key). See `CODING_STANDARDS.md`.

**Fix (narrower than originally proposed):** keep the ID-based lookup, but add a clearer guard or
error message for the non-production case — e.g. a seed task that creates these tags with known
IDs in dev, or a rescue that raises a more informative error naming the constant and its expected
seed data.
