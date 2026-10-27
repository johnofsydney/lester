# `RecordPersonOrGroup` classifier has no debug mode and little structure

**File:** `app/services/record_person_or_group.rb`

The `person_or_group` method is ~130 lines of sequentially-checked regex patterns with no
structure:

- No way to tell which pattern classified a given name — if a donor is misclassified as
  person/group, there's no debug path.
- Match ordering matters (returns on first hit) but isn't documented.

This is mission-critical code — misclassification corrupts the entire donation dataset.

**Fix:** Extract specific-name overrides into a constant array. Add a debug mode that reports
which rule matched. Document why match ordering matters.
