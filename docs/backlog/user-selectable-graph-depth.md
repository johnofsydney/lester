**Status: partially implemented (2026-08-29).** The read-side slicing envisioned below is now live —
`InertiaController#nodes` filters cached `consolidated_descendents` by `depth` (param, session, or
default 2), fixing a pre-existing bug where the `depth` param/session/default machinery already
existed but was never actually applied. No UI control to choose depth exists yet (only the `depth`
URL param and session, no visible selector) — that's the remaining piece of this backlog item.
The "explicitly deferred" section below (querying beyond the cached max) is still fully open.

# Let the user choose how many degrees of the graph to view

**Files:** `app/models/concerns/node_methods.rb#to_h`, `app/models/descendent.rb`,
`app/models/concerns/cached_methods.rb` (`RehydratedNode`)

**Context:** raised during the Capped-node design discussion. Depth is currently fixed and baked
into the cache: `NodeMethods#to_h` calls `consolidated_descendents(depth: 4)` with a hardcoded
`4`, and the whole cached payload is built once per node per week from that single fixed-depth
result — there's no live-DB fallback for rendering (see [[cached-data-json-column-size]]'s
"important constraint" note).

**Decided (first version): keep a fixed cache depth (matches today, 4), let the view slice down.**
`Descendent#to_h` already carries a `depth` field per node — a read-side change to
`RehydratedNode`/the view can filter the already-cached `consolidated_descendents` down to any
depth ≤ the cached max, giving users a depth selector with no new DB queries and no traversal/cache
architecture changes. This is a pure read-side feature.

**Explicitly deferred, not decided:** whether users should be able to request depths *beyond* the
cached max (e.g. depth 6 when cache is built at 4). That's a materially bigger problem — either
caching at a much larger max depth than typically needed (bigger payloads, compounding the
[[cached-data-json-column-size]] concern), or a live, uncached query path for the deeper case
(new performance characteristics, breaks the "cache is the only read path" assumption). Current
view: undecided — the fixed-depth-with-view-slicing approach may be sufficient indefinitely: "the
current way works fine, and slicing on a depth field will work pretty well too." Revisit only if a
concrete need for deeper live queries emerges.
