# `Person` model: double `include`, dead OpenStruct code, and a dead assignment

**File:** `app/models/person.rb`

**a) `ExternalIdentifiable` is included twice** (lines 6 and 14). Rails concerns are idempotent so
it doesn't break anything, but it signals the file hasn't been reviewed carefully.

**b) `#transfers` is acknowledged dead:**
```ruby
def transfers
  # TODO: Potentially useless code
  OpenStruct.new(
    incoming: Transfer.where(taker: self), # always nil. replace with [] ?
    outgoing: Transfer.where(giver: self, giver_type: 'Person').order(amount: :desc)
  )
end
```
Not called by any controller or view (only the cached path is used).

**c) Dead assignment in `#first_degree_transfers`:** an `OpenStruct.new(...)` is evaluated but its
return value is never used — the next line begins the actual return logic.

**Fix:** Remove the duplicate include. Audit whether `transfers` and `first_degree_transfers` are
called anywhere (a grep suggested they're only used by `tweet_body`, itself only called from one
controller action). If `transfers` is genuinely unused, delete it; remove the dead assignment and
dead OpenStruct either way.
