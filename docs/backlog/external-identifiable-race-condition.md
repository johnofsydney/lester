# `set_external_identifier` in `ExternalIdentifiable` has a find-or-initialize race

**File:** `app/models/concerns/external_identifiable.rb:30-36`

`find_or_initialize_by` + `save!` can race under concurrent ingestion — two workers could both
initialise the same record and one will fail on the unique constraint.

**Fix:** Use `find_or_create_by!` (safer under concurrency) or rescue
`ActiveRecord::RecordNotInvalid` and retry once.
