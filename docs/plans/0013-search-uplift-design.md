# Search uplift: faceted advanced search + trigram-tolerant simple search

**Status:** Proposed (design doc — implementation not started)

## Problem

The only search on the site is `SearchController#index` (`app/controllers/search_controller.rb`), which also serves the front page (`root 'search#index'`, `config/routes.rb:42`):

```ruby
class SearchController < ApplicationController
  def index
    @search_term = params[:query]
    @results = PgSearch.multisearch(@search_term).page(params[:page])
  end
end
```

This matches only on `name` (`Person`/`Group`/`TradingName` each declare `multisearchable against: [:name]`), with no filtering by entity type, no category/tag logic, and no fuzzy or accent-insensitive matching — `pg_trgm`/`unaccent` aren't enabled (`db/schema.rb` only enables `plpgsql`).

Meanwhile the domain model already has rich, queryable structure for exactly the kind of question raised in issue #321 ("who belongs to category A and B, or C"): `Tag` is an STI subclass of `Group` (`app/models/tag.rb`), and category/affiliation membership is recorded via the polymorphic `Membership` (`member`: Person or Group → `group`). `HomepageCategories` (`app/views/components/homepage_categories.rb`) already lists `Tag.all` as browsable cards, but there's no way to combine tags/groups into a single query. This is a filtering/UI gap, not a data-modelling one.

Scope, confirmed on the issue thread:
- Keep the existing simple name search's UX, route, and behaviour untouched ("works great, not broken, don't change it") — but do use this pass to add trigram/unaccent matching underneath it, since the extensions aren't enabled yet.
- Add a **new, separate** advanced/faceted search, visible on the same front page, built from chained filters: entity type (Person/Group), then repeatable `[AND|OR] [Category|Group] [value]` rows, e.g. `Person AND Lobbyist (Tag) AND NSW Parliament (Group)`.
- All `Tag` rows are filterable (no curation).
- In scope: `Person`, `Group`, `Tag` (STI Group), `Membership`. Out of scope: `Transfer` (money flow) filtering — a good future idea, not this pass.
- Scale: `Person.count` ≈ 217k, `Group.count` ≈ 133k (checked in prod, 2026-08-30).

## Decision

Two independently shippable pieces.

### A. Simple search — matching-quality upgrade only, no UX/route change

- Migration: `enable_extension 'pg_trgm'`, `enable_extension 'unaccent'`.
- Add a GIN trigram index on `pg_search_documents.content` (the current table only indexes the polymorphic `(searchable_type, searchable_id)` pair, per `db/schema.rb:204-211` — no index supports a `content` scan at all today, so `PgSearch.multisearch` performance already depends entirely on the tsvector query planner, not a stored index; a GIN trigram index is a straight improvement, not a change in strategy).
- Change each model's `multisearchable` declaration (`Person`, `Group`, `TradingName`) to include a trigram matching strategy alongside the existing `tsearch` behaviour, so partial words and typos surface (e.g. `using: { tsearch: { prefix: true }, trigram: {} }`). Verify at implementation time whether `pg_search` 2.3.7 (current `Gemfile.lock` pin) supports `ignoring: [:accents]` to fold accents through `unaccent()` automatically; if not available in this version, unaccent both the indexed `content` and the query term explicitly in the multisearch call.
- No changes to `SearchController#index`, `app/views/search/index.html.erb` markup/copy, or routes. The box on the front page keeps behaving identically from a user's point of view — same input, same results shape, same pagination — just with better recall under the hood.

### B. Advanced/faceted search — new, additive UI + query builder

**Where it lives:** on the same front page as the simple search (`app/views/search/index.html.erb`), as a clearly separate section (e.g. a collapsible "Advanced search" panel below the existing hero/search box), not a standalone page. This keeps both search modes visible from the homepage as required, while making it visually obvious they're two different tools.

**New controller/route:** a dedicated `AdvancedSearchController#index` (`get 'search/advanced' => 'advanced_search#index'`), separate from `SearchController`, so the existing simple-search action, its params (`query`, `page`), and its tests stay untouched. The homepage view renders both: the existing form posting to `search#index`, and a new form posting to `advanced_search#index` (or submitting via `turbo_frame`/plain GET — final choice at implementation time, defaulting to plain GET so results are shareable/bookmarkable via URL).

**Filter model, matching the confirmed UI sketch:**
- Row 1 (fixed): entity type — `[Person, Group]`.
- Row 2+ (repeatable, add/remove): `[AND|OR]` join operator, `[Category|Group]` facet type, then a facet-value picker:
  - Facet type = **Category** → a plain `<select>` of `Tag.all` (a few dozen rows today — same data source `HomepageCategories` already uses, safe as a literal `<select>`).
  - Facet type = **Group** → `Group.all` is ~133k rows, too large for a literal `<select>`. This needs a typeahead/autocomplete input, backed by a small new JSON endpoint (e.g. `GET /search/advanced/groups.json?q=...`, trigram-backed, capped to ~20 results) rather than rendering all groups client-side.
- Optional trailing text box: "search within these results" — a further name filter applied on top of the already-faceted result set (implemented as a plain `WHERE name ILIKE`/trigram-similarity filter on the relation already produced by the facet chain — no need to route this through `pg_search_documents`, since the universe is already narrowed).

**Query semantics.** The confirmed example (`Person AND Lobbyist AND NSW Parliament`) is a flat chain with no parentheses/precedence. To keep this well-defined and explainable, evaluate rows as a left-to-right fold rather than introducing operator precedence:

```
scope = (entity_type == 'Person' ? Person.all : Group.all)
for each subsequent row (op, facet_type, facet_value):
  condition = <has a Membership where group_id = facet_value.id>
  scope = (op == 'AND') ? scope.merge(condition) : scope.or(condition)
```

Each `condition` is an `EXISTS` subquery against `memberships`, e.g. for Person:

```sql
EXISTS (
  SELECT 1 FROM memberships
  WHERE memberships.member_type = 'Person'
    AND memberships.member_id = people.id
    AND memberships.group_id = ?
)
```

This should be encapsulated in a small, unit-testable service object (e.g. `AdvancedSearch::Query.new(entity_type:, filters:).results`, returning a paginated `ActiveRecord::Relation`) rather than built ad hoc in the controller — both because the AND/OR fold logic deserves direct test coverage independent of HTTP params, and because `.or` in Rails requires structurally identical relations, which is easiest to guarantee by constructing every condition through the same helper.

**Indexes.** `memberships` already carries `(group_id)`, `(member_type, member_id)`, and `(group_id, member_type, member_id)` indexes (from earlier migrations), which is exactly what the `EXISTS` pattern above needs — no new membership indexes required. The only new index needed for part B is a GIN trigram index on `groups.name`, to back the Group-facet autocomplete endpoint. (Two recent migrations, `20260329233226` and `20260329233440`, *removed* `LOWER(name)` btree indexes from `people`/`groups` — worth a one-line note in the PR since a new trigram index looks superficially similar, but it's a different index type serving a different query pattern, not a reintroduction of what was removed.)

**Front-end.** The app currently has no real Stimulus controller (`app/javascript/controllers/` only has the generated `hello_controller.js` placeholder) and the homepage form has zero JS today. Adding/removing filter rows and driving the Group-facet autocomplete both need a first genuine Stimulus controller (e.g. `advanced_search_controller.js`), plus a small typeahead library (Tom Select or Choices.js) for the Group picker. This stays consistent with the app's plain Rails/ERB + Phlex conventions — the separate Inertia/React pipeline is reserved for the network graph page and would be a poor fit for a form-heavy filter builder.

## Rollout (phased PRs)

| # | PR | Content |
|---|----|---------|
| 1 | Simple search matching upgrade | `pg_trgm`/`unaccent` extensions, trigram index on `pg_search_documents.content`, updated `multisearchable` strategy on `Person`/`Group`/`TradingName`. No UI change. |
| 2 | `AdvancedSearch::Query` service + specs | Entity type + AND/OR fold + Tag/Group facet filtering, pure Ruby/AR, no controller/UI yet. |
| 3 | Group-facet autocomplete endpoint | Trigram index on `groups.name`, `GET /search/advanced/groups.json`. |
| 4 | Advanced search UI | `AdvancedSearchController#index`, homepage form, first Stimulus controller for dynamic filter rows, wired to the service from PR 2. |
| 5 (optional) | "Search within results" | Trailing name filter on the faceted relation. |

## Known follow-ups (not part of this epic)

- `Transfer` (donations / government contracts) filtering — e.g. "recipients of donations over $X" — explicitly deferred by the issue; a natural next epic once the Membership-based facet builder is proven out.
- Curated/grouped tag categories in the UI (all tags stay filterable and unstructured for this pass).
- Saved/shareable searches — falls out naturally if the advanced search stays GET-with-params, worth its own follow-up if wanted.
- Parenthesised/precedence-aware boolean queries beyond the flat left-to-right AND/OR fold.

## Why not deeper fixes

- **Not adopting a dedicated search engine (Elasticsearch/OpenSearch/etc.)**: at ~350k total rows across `people`/`groups`, `pg_trgm` plus indexed `EXISTS` joins on `memberships` is sufficient and keeps the stack Postgres-only, with no new operational dependency.
- **Not merging simple and advanced search into a single form**: the issue thread was explicit that the simple box "works great, not broken, don't change it." Keeping them as two additive, clearly separated affordances avoids any risk of regressing the default homepage experience.
- **Not building the filter UI on the existing React/Inertia pipeline**: that stack is scoped to the network graph page. A form-heavy, mostly server-rendered filter builder is a better fit for this app's dominant ERB/Phlex + light-Stimulus pattern than introducing a second SPA surface.

## Open questions for implementation time

- Whether `pg_search` 2.3.7 supports `ignoring: [:accents]` directly, or whether `unaccent()` needs to be applied manually in the multisearch query.
- Exact UI treatment for the advanced search panel (accordion vs. always-visible section) — deferred to a first-draft mockup in PR 4.
