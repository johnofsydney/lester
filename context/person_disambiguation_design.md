# Person Disambiguation Design

## Problem

People are ingested from many different sources. Currently there is no way to differentiate two people with the same name. `RecordPerson` uses a name-only `find_or_create_by`, and a unique `lower(name)` index on `people` enforces at the DB level that no two people can share a name.

## Current State

- [`RecordPerson`](../app/services/record_person.rb) resolves people by name only via `Person.find_or_create_by(name:)`.
- [`RecordPersonOrGroup`](../app/services/record_person_or_group.rb) can pass `aec_id` through to `RecordPerson`, but it is currently unused for matching.
- `people.aec_id` exists and is already uniquely indexed in the DB schema.
- The model has a manual `cleanedUpName` canonicalisation step with hardcoded name corrections (a stopgap).
- [`Admin::People::ExplodePerson`](../app/services/admin/people/explode_person.rb) is the current corrective mechanism: it splits one merged person into many, assigning each to a specific membership context. It is too primitive to be the only long-term solution.

## Agreed Design Decisions

### 1. Name aliases via `trading_names`

Every name variant seen during ingestion for a person should be stored in `trading_names` (same pattern used for groups with ABNs). If an ID-matched person arrives with a new name variant:
- **Add the new name to `trading_names`.**
- **Do NOT update the person's canonical `name` field.** The canonical name is stable once set.

### 2. No-ID imports — assume same person

If no external identifier (e.g. `aec_id`, `acnc_id`) is available, treat an incoming name as matching the existing person with the same normalised name. i.e. "john smith" in the import IS assumed to be the same as "John Smith" in the database.

Human-assisted correction (via `ExplodePerson` or future tooling) handles the cases where this assumption is wrong.

### 3. `disambiguated_name` — unique, stable, display-first

Drop the unique constraint on `person.name` and introduce a `disambiguated_name` column that:
- Is **unique**.
- Is **immutable once set** (only changeable by an admin).
- Takes precedence over `name` in all display contexts.
- Initially auto-generated as `name` if unique, or `name #{id}` if a duplicate exists (e.g. `"John Smith 100"`, `"John Smith 201"`).

## Phased Implementation Plan

### Phase 1 — Ingestion correctness (no schema changes yet)

Update [`RecordPerson`](../app/services/record_person.rb) to resolve identity in this order:

1. If `aec_id` present → match by `aec_id` first.
2. If matched by ID and incoming name differs from canonical name → add new name to `trading_names` (do not update `name`).
3. If no ID → fall back to normalised name matching (current behaviour).
4. On create → also write canonical name to `trading_names` so all name variants are consistently tracked there.

Future external IDs (`acnc_id`, etc.) follow the same pattern.

### Phase 2 — Schema: allow duplicate names

- Drop the unique `lower(name)` index.
- Remove the `validates :name, uniqueness:` model validation.
- Keep a non-unique index on `name` for query performance.

This unblocks two genuinely different people sharing a name from coexisting in the DB.

### Phase 3 — `disambiguated_name`

- Add `disambiguated_name` column (nullable initially).
- Backfill:
  - Where name is currently unique → `disambiguated_name = name`.
  - Where duplicates exist → `disambiguated_name = "#{name} #{id}"`.
- Add unique index on `lower(disambiguated_name)`.
- Update all view helpers, serialisers, and search to prefer `disambiguated_name`, falling back to `name`.

### Phase 4 — Better conflict tooling (future)

Evolve `ExplodePerson` into a richer admin flow:
- Candidate cluster detection (people with same name, conflicting context).
- Guided merge / split UI.
- Audit trail for identity decisions.
- Potentially a separate `person_identifiers` table:
  ```
  person_identifiers(id, person_id, source, value)
  # unique index on (source, value)
  # sources: :aec, :acnc, etc.
  ```
  This scales better than adding more ID columns to `people`.

## Behaviour Matrix for `RecordPerson`

| Scenario | Behaviour |
|---|---|
| New person, no ID | `find_or_create_by(name:)`, add name to `trading_names` on create |
| New person, has `aec_id` | Find by `aec_id`, create if not found; add name to `trading_names` |
| Known person (by `aec_id`), same name | No-op |
| Known person (by `aec_id`), new name variant | Add new name to `trading_names`; do NOT change canonical `name` |
| Known person (by name), no ID | Return existing person |
| Same canonical name, no ID, genuinely different people | Merged for now; `ExplodePerson` used to correct later |

## Open Questions / Future Decisions

- Should `disambiguated_name` be shown to end users everywhere, or only surfaced when ambiguity exists in a given context?
  - Recommendation: everywhere initially for consistency, then collapse to `name` in context where it is unambiguous.
- What triggers automatic cluster detection for likely duplicates?
- Should `ExplodePerson` carry forward `trading_names` from the source person to each newly created person?
