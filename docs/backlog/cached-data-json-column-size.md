# `cached_data` jsonb column may be growing too large per node

**Files:** `app/models/concerns/cached_methods.rb`, `app/models/concerns/node_methods.rb#to_h`

**Context:** `cached_summary` (the `summary` key inside the `cached_data` jsonb column on Person
and Group) stores the full traversal result — `consolidated_descendents`, `consolidated_transfers`,
`direct_connections`, top-six giver/taker lists, money in/out, data time range, etc. — for
potentially many degrees of the graph. No current check on payload size; a highly-connected node
(a major party, a big donor) could produce a very large JSON blob per row. Concern raised
alongside the [[node-methods-and-cached-methods-tangled-concerns]] discussion — reshaping which
data belongs in the cache is a natural point to also address size.

**Important constraint:** `cached_data` is not an optimisation on the side — it is the sole data
source for the entire node-detail view (via `RehydratedNode`). There is no fallback path that
queries the DB directly for view rendering. This means any change to what's stored must be done by
adding/reshaping fields the view still needs, not by simply trimming for size — trimming something
the view reads would break the page, not just make it leaner.

**Fix:** not yet investigated. Worth measuring actual `cached_data` column sizes in production
(distribution, max, table bloat) before deciding whether to trim what's stored, cap depth/fan-out
in the cached payload, or move parts of it to a separate table/format. Any such change needs to be
checked against every view that reads through `RehydratedNode`, not just against payload size.
