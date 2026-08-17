# Transfer uniqueness validation doesn't match the actual DB constraint

**File:** `app/models/transfer.rb:11-14`

The AR `validates_uniqueness_of` and the `schema.rb` unique index don't cover the same columns.
The validation gives a misleading error message and the real enforcement is a DB exception that
surfaces as a 500.

**Fix:** Align the `validates_uniqueness_of` with the actual unique index columns so the
validation catches conflicts before hitting the DB and produces a clean error.

Pairs with `docs/backlog/no-record-transfer-uniqueness-specs.md` — add the spec once this is
fixed.
