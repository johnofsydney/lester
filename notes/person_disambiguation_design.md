# Person Disambiguation Design

## Current status (2026-07-19): Done — historical design record

Both phases below are implemented and covered by specs. This doc is kept as a record of the reasoning, not as a live plan — treat it as superseded rather than in-progress.

What exists today:
- `external_identifiers` — polymorphic (`owner_type`/`owner_id`), `source` + `value` columns, unique index on `(owner_type, owner_id, source, value)`. See `db/schema.rb`, `app/models/external_identifier.rb`, `app/models/concerns/external_identifiable.rb`. (Note: the table is correctly spelled `external_identifiers` — this doc originally proposed the misspelling `external_identifers` as "intentional project naming"; that never happened, the migration uses the correct spelling.)
- `trading_names` — polymorphic alias table, unique on `(owner_type, owner_id, name)`. See `app/models/trading_name.rb`, used via `has_many :trading_names, as: :owner` on `Person`/`Group`.
- `People::RecordPerson` routes through `Entity::RecordEntityWithExternalId` whenever an `aec_id`/`acnc_id`/`open_australia_id` is given; falls back to name-only `Person.find_by(name:)`, then creates via `People::Record::RecordPersonWithName` (which also writes the canonical name to `trading_names`).
- `Entity::RecordEntityWithExternalId` implements ID-match-first, then sole-name-match-and-backfill-ID, then create; it adds to `trading_names` whenever an ID match resolves to a different name than the one just seen.
- Spec coverage: `spec/services/people/record_person_spec.rb` has a `'phase 1 identity coverage'` block matching the scenarios below almost verbatim, plus `spec/services/entity/record_entity_with_external_id_spec.rb` and `spec/models/external_identifier_spec.rb`.

`Admin::People::ExplodePerson` remains the correction path for false merges; nothing below changed that.

---

## Original design (below, for context)

### Summary

People are ingested from multiple sources and currently collapse on `name`.
This creates false merges when different people share a name.

The strategy is to:
- Keep a stable canonical `name`.
- Store all observed aliases in `trading_names`.
- Move identifier logic to a dedicated polymorphic table named `external_identifiers`.
- Preserve no-ID name matching for now, with admin split tooling as a correction path.

### Key Decisions

#### 1) Alias capture in `trading_names`

Every imported person name variant must be captured as a trading name for that person.

If an ID-matched person receives a new imported name variant:
- Add the variant to `trading_names`.
- Do not update canonical `people.name`.

#### 2) No-ID behaviour

If no external identifier is provided, assume the imported name maps to the existing person with that normalized name.

This may produce false merges; correction remains via `Admin::People::ExplodePerson` until richer tooling exists.

#### 3) Disambiguated display name

Introduce a unique display field (`disambiguated_name`) later.
Initial generation can be `"#{name} #{id}"` when required.

**Not built.** No `disambiguated_name` field exists on `Person` — display still uses the canonical `name` alone. Revisit if false merges on common names become a practical problem.

### External Identifier Table

Future sources will include additional IDs (for example `open_australia_id`).
Identifier handling should not remain column-per-source on `people`.

Planned shape (built as described, correct spelling):
- Polymorphic owner relation: `belongs_to :owner, polymorphic: true`
- Owner can be `Person` or `Group`
- Store source and value pairs so new identifier systems can be added without schema churn

### Phase Plan (as originally written)

#### Phase 1: Coverage first (specs) — done

Explicit tests in `record_person_spec` for:

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

Also required in Phase 1:
- Tests proving that when a person is created, the name is also written to `trading_names`.

#### Phase 2: External identifiers model — done

Migration, table, and model for `external_identifiers` with polymorphic owner. Built as `db/migrate/20260322000001_create_external_identifiers.rb` and `db/migrate/20260325000000_align_external_identifier_uniqueness.rb`.

### Behaviour Expectations for RecordPerson (Target) — met

1. Create path writes canonical name to `trading_names`.
2. ID match has priority over name-only ambiguity.
3. New alias on ID match updates `trading_names` only.
4. Canonical `people.name` remains stable unless changed explicitly by admin workflow.

### Notes

- `ExplodePerson` remains useful but is not sufficient as the long-term primary disambiguation mechanism.
- Long term, identifier resolution should route through `external_identifiers` rather than per-column identity logic — this is now the case.
