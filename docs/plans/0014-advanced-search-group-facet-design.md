# Advanced search phase 2: filter by plain Group, not just Category

**Status:** Proposed (design doc — implementation not started)

## Problem

The advanced search built in this pass (see `docs/plans/0013-search-uplift-design.md`, PR 4)
lets a user filter Person/Group results by **Category** (a `Tag`) only — `AND`/`OR` chains of
Category filters, with OR-grouping of multiple categories within one row (e.g. "Lobbyists AND
(Consulting OR Superannuation)"). Filtering by an arbitrary **Group** (e.g. "NSW Parliament", or a
specific lobbying firm) instead of a Category is not exposed anywhere in the UI, even though:

- The query layer already supports it. `AdvancedSearch::Query::Filter#facet_type` already accepts
  `'Group'` as well as `'Category'`, and already resolves it correctly (`direct_member_of`, a
  one-hop membership check — no traversal through an intermediate subgroup, unlike the two-hop
  Category+Person case). This was exercised directly in specs and against real dev data during
  phase 1, just never wired up to a form control.
- The data endpoint already exists. `GET /search/advanced/groups.json?q=...`
  (`AdvancedSearchController#group_autocomplete`, added in a separate PR ahead of the UI work)
  does trigram-backed, typo-tolerant group name search, capped at 20 results — built and tested
  standalone, never called from any page.

The reason it's deferred rather than built in the same pass: `Group.count` is ~133k, too many for
a `<select>`, so a Group facet needs a genuine typeahead/autocomplete input — the first real
JavaScript (Stimulus) in this app's advanced search work. Phase 1 deliberately stayed JS-free
(plain `<select>` elements, plain GET submission) so it could ship and be exercised end-to-end
first. This doc scopes the follow-up.

## What phase 1 shipped (context, not part of this doc's scope)

- `AdvancedSearchController#index` (`GET /search/advanced`), homepage link deliberately not added
  yet (`app/views/search/index.html.erb` has no reference to it) — reachable directly for testing.
- `AdvancedSearch::Query` service: entity type (Person/Group) + a left-to-right `AND`/`OR` fold of
  filter rows, each row itself OR-ing one or more facet values (`facet_value_ids`, plural).
  Category+Person is two-hop (via an intermediate subgroup); every other combination is one-hop.
- Two static filter rows in `app/views/advanced_search/_form.html.erb`: row 1 is a single Category
  `<select>`; row 2 adds an `AND`/`OR` joiner and two Category `<select>`s OR'd together.
- The whole form is submitted via plain GET, and the results page re-renders the form with the
  submitted values pre-selected (entity type, both rows' categories, the joiner) — not reset to
  blank — so the results page reads as "what did I search for", not just a bare list.
- `GET /search/advanced/groups.json` exists and works, unconnected to the form.

## What this phase needs to add or change

1. **A per-row Category/Group toggle.** Each row currently hardcodes a hidden
   `facet_type=Category` field. It needs to become a visible `<select>` (Category vs Group) that
   determines which input the row shows.

2. **A Group-picker partial**, alongside the existing `_category_select.html.erb`: a visible text
   input (what the user types), a hidden field carrying the actual selected group id (what
   submits), and a suggestions list rendered under the input.

3. **The first Stimulus controller for this feature**
   (`app/javascript/controllers/advanced_search_controller.js` — auto-registers via the existing
   `eagerLoadControllersFrom` convention in `app/javascript/controllers/index.js`, no build config
   changes needed). Responsibilities:
   - Show/hide the Category `<select>` vs. the Group text input when the row's toggle changes.
   - Debounce keystrokes in the Group input and fetch `/search/advanced/groups.json?q=...`.
   - Render the returned suggestions; on click, populate the hidden id field and show the chosen
     name in the text input; clear suggestions on an outside click.

4. **Server-side name resolution for pre-population.** Phase 1's "don't clear the boxes on the
   results page" behaviour pre-selects Category `<option>`s by id, which works because the
   `<select>` already lists every Tag. A Group typeahead has no such static list — the results
   page needs `AdvancedSearchController#index` to look up the chosen Group(s) by id
   (`Group.where(id: ...)`) and pass their names to the view, so the JS widget can seed the text
   input with a real name instead of a bare id.

5. **Field-order care, same constraint as phase 1.** Rack groups a repeated array-of-hashes query
   key (`filters[][...]`) into a new hash as soon as it sees a repeated subkey (see the
   `facet_type`-must-render-first fix from phase 1, and its regression spec in
   `spec/requests/advanced_search_spec.rb`). Any new Group-picker fields within a row must respect
   the same ordering rule.

## Known constraint: no JS test coverage exists in this app

There is no Capybara/system-test setup anywhere in this repo (`spec/system` does not exist).
Request specs can cover the rendered markup (hidden fields, `data-` attributes, correct
facet-type-toggle markup) and the end-to-end filtering logic once a Group id is already present in
the URL (bypassing the JS entirely, the same way phase 1's Group-facet specs did). The typeahead
interaction itself — typing, seeing suggestions, clicking one — can only be verified manually in a
real browser. This should be called out explicitly in the PR rather than assumed away.

## Open scope question for implementation time

Phase 1's row 2 OR-groups two Category values together. Should the Category/Group toggle apply
**per row** (a Group-mode row shows two Group-typeaheads OR'd, mirroring row 2's current shape) or
should the first version of this phase add Group support to **row 1 only**, single value, no
OR-pairing — extending to row 2 / OR-pairing as a later, separately-verified step, consistent with
how phase 1 itself was built in small increments? Leaning towards the latter: ship the typeahead
working once, end to end, before generalizing it into the OR-pairing slot.

## Out of scope (unchanged from phase 1's doc)

- `Transfer` (donations/government contracts) filtering.
- Curated/grouped tag categories.
- Parenthesised/general-precedence boolean queries beyond the flat left-to-right `AND`/`OR` fold
  (the two-level AND-of-ORs shipped in phase 1 covers the concrete case that was asked for without
  needing this).
- Making advanced search reachable from the homepage — still deliberately unlinked pending
  further UX work, per phase 1.
