# `RecordPersonOrGroup` classifier has duplicate patterns, typos, and no debug mode

**File:** `app/services/record_person_or_group.rb`

The `person_or_group` method is ~130 lines of sequentially-checked regex patterns with no
structure:

- `regex_for_company_words_13` and `regex_for_company_words_14` are **identical** — one is dead.
- `regex_for_specific_companies_1` and `regex_for_campaign_words_3` are also identical.
- "Constitutional" is misspelled "Constituional" in two patterns — those never match.
- No way to tell which pattern classified a given name — if a donor is misclassified as
  person/group, there's no debug path.
- Match ordering matters (returns on first hit) but isn't documented.

This is mission-critical code — misclassification corrupts the entire donation dataset.

**Fix:** Consolidate the ~14 company-word patterns into one combined regex. Extract specific-name
overrides into a constant array. Add a debug mode that reports which rule matched. Fix the typos.
Delete the dead duplicate patterns.
