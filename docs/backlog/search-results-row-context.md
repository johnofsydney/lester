# Search result rows show a bare name + link, no context

**Files:** `app/views/components/search_results.rb`, used by both `app/views/search/index.html.erb`
(simple search) and `app/views/advanced_search/index.html.erb` (advanced search, added in the
search uplift work — see `docs/plans/0013-search-uplift-design.md`).

Every search result — simple or advanced — renders as just a linked name (plus, for `TradingName`
results only, the owner's name in brackets). There's no way to tell from the results list:

- **Which categories/tags a Person or Group actually belongs to** — relevant on any result, but
  especially sharp for advanced search: once a query combines multiple filters (e.g. "Lobbyists
  AND (Consulting OR Superannuation)"), the results list gives no visual confirmation of *why* a
  given row matched, or what else that person/group is tagged with beyond the filter that was
  searched for.
- Any other identifying context (e.g. current/former status of a membership, a snippet of what
  matched for simple search's trigram/fuzzy hits).

This surfaced twice independently: once during the original advanced-search design work, and again
during a UX pass on the shipped advanced search UI (result count and empty-state messaging were
fixed then; this — richer result rows — was flagged as the harder, not-yet-scoped piece).

## Why this is a shared, not advanced-search-only, concern

Both search surfaces render through the same `SearchResults` component (a deliberate reuse
decision — see `docs/plans/0013-search-uplift-design.md`'s "Implementation notes" section), so any
uplift to result-row richness benefits both simple and advanced search from one change, rather than
needing two separate builds.

## Not yet scoped

This is flagged, not designed. Before picking it up, worth deciding:

- What context is actually worth showing per row without turning a scannable list into a cluttered
  one — likely just 1-2 tag chips, not a full profile summary.
- Whether it differs meaningfully between simple search (bare name matches, no filter context to
  reference) and advanced search (where the applied filters are known and could be highlighted if
  they match).
- Performance: showing a person's/group's tags means an extra query (or eager-loaded join) per
  result row, which needs to stay cheap at Kaminari's page size (25).
