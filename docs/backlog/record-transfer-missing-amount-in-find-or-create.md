# `RecordTransfer` doesn't include `amount` in `find_or_create_by!`

**File:** `app/services/record_transfer.rb:22`

```ruby
Transfer.find_or_create_by!(giver:, taker:, effective_date:, transfer_type:, evidence:)
# amount is not here — so if the same transfer arrives with a revised amount, it's silently ignored
```

Two different amounts for the same transfer (e.g. an amended AEC disclosure) will return the first
record unchanged. Cached aggregate totals will be wrong.

**Fix:** Include `amount:` in the `find_or_create_by!` call, or use `find_or_create_by!(...)` then
`update!(amount:)` if found (depending on desired semantics — keep highest? keep latest?).
