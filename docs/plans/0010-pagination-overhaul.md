# Pagination overhaul: adopt kaminari everywhere

**Status:** Completed (PRs #266, #274, #279, #281, #283, #294, and this cleanup PR)

## Problem

GitHub issue #226 documented that this app had no single working pagination implementation.
Two uncoordinated page-size definitions existed (`Pagination` concern's `default_per_page=250`
vs `Constants::PAGE_LIMIT=25`), the three list-index controllers each redefined their own
`page_size` with a dead `return 250` masking the mismatch, a group tab had pagination silently
ripped out (`# This action used to have pagination. TODO: re-add pagination into the new
format?`), a page-nav component was written but its call site commented out, and search had no
pagination attempted at all. `kaminari` was already installed as a transitive dependency (via
`activeadmin`) but unused outside ActiveAdmin's own views.

While scoping the fix, we widened it: every list of People, Groups, or Transfers anywhere in the
app — not just the three index pages — should be paginated. A codebase survey found 8 such
surfaces, two of which (`People::GroupsTable`, `TransfersTableComponent`) weren't in the original
issue at all. `Groups::ShowView` already had a `# all these components need pagination` comment
anticipating this.

## Decision

- Fully adopt kaminari as the single pagination mechanism; retire the homegrown `Pagination`
  concern and `Constants::PAGE_LIMIT` entirely, in favour of kaminari's out-of-the-box default
  (25/page) everywhere — no per-surface overrides.
- Standard `?page=N` query-string pagination everywhere, replacing the custom `/model/page=:page`
  routes. Clean break, no backward-compat redirects for the old URLs.
- One shared Phlex page-nav component (`Common::PageNav`), replacing both the old
  `Common::PageNav` and the duplicated, never-called `Groups::PeopleTable#page_nav`. It accepts
  any kaminari-paginated collection (`collection:`, responding to `current_page`/`total_pages`)
  plus a `path:` for building page links — used via `render` from both Phlex components and ERB
  views.
- For the 3 surfaces backed by in-memory arrays deserialized from the `cached_data` jsonb column
  (Group→People, Group→Affiliated Groups, Person→Groups), pagination is applied via
  `Kaminari.paginate_array` on the full deserialized array. This does not avoid loading the whole
  array into memory — that's a separate, bigger change to `CachedMethods`/`RehydratedNode`,
  explicitly out of scope here.
- Search gets full kaminari pagination (not a capped "top N, refine your search" UX).
- New `spec/requests` directory (none existed in this repo before) with minimal coverage per
  surface: default page size, page 2 doesn't repeat/skip page 1's rows.

## The 8 paginated surfaces

| # | Surface | Controller/Component | Data source | Pagination style |
|---|---|---|---|---|
| 1 | `/people` index | `PeopleController#index` → `People::IndexView` | AR relation | `.page.per` |
| 2 | `/groups` index | `GroupsController#index` → `Groups::IndexView` | AR relation | `.page.per` |
| 3 | `/transfers` index | `TransfersController#index` → `Transfers::IndexView` | AR relation | `.page.per` |
| 4 | Group → People tab | `GroupsController#group_people` → `Groups::PeopleTable` | in-memory array | `Kaminari.paginate_array` |
| 5 | Group → Affiliated Groups tab | `GroupsController#affiliated_groups` → `Groups::AffiliatedGroups` | in-memory array | `Kaminari.paginate_array` |
| 6 | Person → Groups list | `People::GroupsTable` (on `people#show`) | in-memory array | `Kaminari.paginate_array` |
| 7 | Person/Group → Transfers list | `TransfersTableComponent` (on `people#show` / `groups#show`) | in-memory array | `Kaminari.paginate_array` |
| 8 | `/search` | `SearchController#index` → `SearchResults` | AR relation (`PgSearch.multisearch`) | `.page.per` |

## Rollout

Landed as a sequence of small, independently mergeable/deployable PRs rather than one large
change:

1. **Foundation** (this PR) — add `kaminari` as a direct dependency, delete the `Pagination`
   concern and `Constants::PAGE_LIMIT`, rebuild `Common::PageNav`, migrate the 3 index pages,
   switch their routes to `?page=N`, add the first `spec/requests` specs.
2. Group → People tab
3. Group → Affiliated Groups tab
4. Person → Groups list
5. Person/Group → Transfers list
6. Search
7. Cleanup — remove the remaining `page=:page` custom routes, retire the now-unneeded
   `.rubocop_todo.yml` exclusions for `Lint/UnreachableCode` on the 3 index controllers.

## Known follow-ups (not part of this epic)

- [#293](https://github.com/johnofsydney/lester/issues/293) — the Person/Group → Transfers list
  (surface 7) pages noticeably slower than the array-backed People/Groups lists, most likely due
  to `consolidated_transfers` being an unbounded array (unlike graph-traversal-bounded
  `direct_connections`) plus `summarise_for`'s `group_by` rerunning on every page navigation.
- Three pre-existing dead views were noticed but left untouched, since fixing them wasn't part of
  fixing pagination: `app/views/groups/show.html.erb` (references classes that no longer exist),
  and `app/views/lazy_load_people/show.html.erb` / `lazy_load_groups/show.html.erb` (call
  `TransfersTableComponent` with a `remove_zero_degrees:` kwarg the component doesn't accept).
  All three are unreachable — `#show` always renders the Phlex view instead — but they'd raise if
  that ever changed.

## Why not deeper fixes

- **Not restructuring `CachedMethods`/`RehydratedNode`** to allow DB-level pagination of the
  cached-array-backed lists. The array is already fully deserialized for other purposes on these
  pages; that's a separate architectural question from "these lists render unbounded rows."
- **Not adding full system/browser specs.** Request specs are enough to verify the pagination
  logic (correct page size, no repeated/skipped rows); UI click-through coverage is a larger,
  separate investment given this repo had zero request/system/view specs to start from.
