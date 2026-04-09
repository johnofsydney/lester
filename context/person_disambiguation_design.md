# Person Disambiguation Design

## Summary

People are ingested from multiple sources and currently collapse on `name`.
This creates false merges when different people share a name.

The strategy is to:
- Keep a stable canonical `name`.
- Store all observed aliases in `trading_names`.
- Move identifier logic to a dedicated polymorphic table named `external_identifers` (intentional project naming).
- Preserve no-ID name matching for now, with admin split tooling as a correction path.

## Key Decisions

### 1) Alias capture in `trading_names`

Every imported person name variant must be captured as a trading name for that person.

If an ID-matched person receives a new imported name variant:
- Add the variant to `trading_names`.
- Do not update canonical `people.name`.

### 2) No-ID behaviour

If no external identifier is provided, assume the imported name maps to the existing person with that normalized name.

This may produce false merges; correction remains via `Admin::People::ExplodePerson` until richer tooling exists.

### 3) Disambiguated display name

Introduce a unique display field (`disambiguated_name`) later.
Initial generation can be `"#{name} #{id}"` when required.

## Elevated Priority: External Identifier Table

Future sources will include additional IDs (for example `open_politics_id`).
Identifier handling should not remain column-per-source on `people`.

Preferred table name for this project:
- `external_identifers`

Planned shape:
- Polymorphic owner relation: `belongs_to :owner, polymorphic: true`
- Owner can be `Person` or `Group`
- Store source and value pairs so new identifier systems can be added without schema churn

## Phase Plan

### Phase 1: Coverage first (specs)

Add explicit tests in `record_person_spec` for:

1. When no existing person with a given name exists:
- `name` only creates a new person
- `name + aec_id` creates a new person
- `name + acnc_id` creates a new person

2. When an existing person with a name exists:
- `name` only does not create a new person
- `name + aec_id` does not create a new person and sets `person.aec_id`
- `name + acnc_id` does not create a new person and sets `person.acnc_id`

3. When an existing person with `name + aec_id` exists (no `acnc_id`):
- `name` only does not create a new person
- `name + same aec_id` does not create a new person
- `name + different aec_id` creates a new person with that `aec_id`
- `name + acnc_id` does not create a new person and sets `person.acnc_id`

Phase 1 is intentionally coverage-first; failing tests are expected.

Also required in Phase 1:
- Tests proving that when a person is created, the name is also written to `trading_names`.

### Phase 2: External identifiers model (do not implement yet)

Create migration, table, and model for `external_identifers` with polymorphic owner.

Not in scope for current code changes.

## Behaviour Expectations for RecordPerson (Target)

1. Create path writes canonical name to `trading_names`.
2. ID match has priority over name-only ambiguity.
3. New alias on ID match updates `trading_names` only.
4. Canonical `people.name` remains stable unless changed explicitly by admin workflow.

## Notes

- Existing `ExplodePerson` remains useful but is not sufficient as the long-term primary disambiguation mechanism.
- Long term, identifier resolution should route through `external_identifers` rather than per-column identity logic.
