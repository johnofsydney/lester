# `RecordDonation` is dead and contains typos that would corrupt data if it were ever re-enabled

**File:** `app/services/record_donation.rb`

- `initialize` and `call` both start with bare `raise` — the class is completely non-functional.
- `person_or_group` has `return 'goup'` (typo) — not 'group'. Would route matched records to an
  unknown branch.
- The regex logic is an older, narrower subset of `RecordPersonOrGroup` — it would misclassify
  donors.

**Fix:** Delete the file entirely. If the `person_or_group` regex logic needs to be compared with
`RecordPersonOrGroup`, do it via git history, not a dead production file.
