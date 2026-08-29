# Consider building the new graph pipeline as a parallel, swappable system

**Context:** raised while designing the Capped-node rework
([[large-groups-should-terminate-not-exclude]]). The graph pipeline has four independent stages —
traversal/building (`BuildQueue`/`CanAddToQueue`), caching (`Cache::Build*CachedDataJob`),
rehydrating (`RehydratedNode`/`CachedMethods`), and views. Idea: build the reworked version of each
stage as a parallel implementation that can be swapped in independently, rather than editing the
existing pipeline in place — enabling A/B testing the new traversal/render logic against the old
before committing to it fully.

**Not decided** — raised as an option to keep in mind, not committed to. Would need weighing
against the cost of running two parallel systems (double the cache storage per node, two code
paths to maintain) versus the value of being able to compare old vs new output directly before
cutover.

**Assessment for the Capped/Traversal Budget work specifically (ADR 0007): not needed.**
`BuildQueue`/`CanAddToQueue` is a pure function with no external readers of its intermediate
state, so it can change in place with test coverage as the safety net. The cache
(`cached_summary`) already self-heals on its existing weekly refresh cycle (`cache_fresh?`) — a
node picks up the new traversal shape the next time its own build job runs, no backfill or
side-by-side comparison needed. New fields (e.g. `capped` on `Descendent#to_h`) are additive and
safe for existing readers. Parallel-track cost (double storage, two code paths) isn't justified
here because the output shape isn't changing enough to need it.

**Where this idea would earn its cost:** a change where old and new output can't coexist in one
cache row, or where the new logic is genuinely untrusted and needs eyeballing against real data
before commit, or where the migration itself is slow/risky. The strongest current candidate is the
transfer-edges-as-real-graph-edges work ([[transfer-edges-not-counted-as-graph-degree]]) — that
changes what `nodes`/`nodes_count` mean fundamentally, is a much bigger shape change, and might
justify this pattern when it's tackled.
