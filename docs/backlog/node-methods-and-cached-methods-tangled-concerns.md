# `NodeMethods` and `CachedMethods` no longer have a clear separation of purpose

**Files:** `app/models/concerns/node_methods.rb`, `app/models/concerns/cached_methods.rb`,
`app/models/concerns/cached_methods.rb` (`RehydratedNode`)

**Context:** the intent is a clean split — one concern responsible for querying the live DB and
building the cache payload (write side), and one responsible for re-extracting/shaping data
already sitting in the `cached_data` jsonb column for display (read side). In practice this has
drifted into three places doing overlapping work:

- `NodeMethods#to_h` (`app/models/concerns/node_methods.rb:44`) is the expensive live-DB traversal
  that produces the cache payload — clearly write-side.
- But `NodeMethods` also has `direct_connections`, `top_six_as_giver`, `top_six_as_giver`,
  `name_for_bar_graph`, etc. — these look like display/shaping concerns, and `RehydratedNode`
  (defined inside `cached_methods.rb`) has near-duplicate read-side methods for the same concepts
  (`direct_connections`, `top_six_as_giver`, `people`, `affiliated_groups`) that pull from
  `cached_summary` instead.
- `RehydratedNode` itself carries TODOs questioning its own storage shape (hash vs OpenStruct) and
  says outright "wherever they go, put less things into cached_summary."

**Fix:** decide the real boundary — likely "build the cache" (DB query → payload) vs "read the
cache" (payload → view-ready shape) — and move methods to the concern that matches, so a reader
doesn't have to check three files to find where a given piece of graph data comes from. Related to
[[transfer-edges-not-counted-as-graph-degree]] and the JSON cache size concern
(docs/backlog/cached-data-json-column-size.md) — any reshaping of the cache payload should
consider both at once.
