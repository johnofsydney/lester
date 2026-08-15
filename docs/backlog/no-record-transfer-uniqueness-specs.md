# No specs for `RecordTransfer` uniqueness or concurrent scenarios

**Fix:** Add a spec that calls `RecordTransfer.call` twice with identical args and asserts only
one `Transfer` is created. Then add a test for the amount-mismatch case once
`docs/backlog/record-transfer-missing-amount-in-find-or-create.md` is resolved.
