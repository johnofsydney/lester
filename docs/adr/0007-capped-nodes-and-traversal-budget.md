---
status: accepted
---

# Large groups are shown as Capped leaves, not excluded from the graph

Today, `CanAddToQueue` conflates "should this node appear in the graph" with "should this node be
expanded further" — a group over `MAX_NODE_COUNT_TO_FOLLOW` (50 members), or any `Tag`, is excluded
from the graph entirely, so e.g. a councillor's party affiliation never appears on their council's
graph even though it's exactly the kind of relationship the graph exists to show. We decided to
split these into two separate checks: a large node still appears as an edge from its parent (a
**Capped** node), but is not enqueued for further expansion. This generalises past the `Tag` special
case entirely — the same `nodes_count` check now governs Person and Group nodes alike, and Tag vs
plain-Group is no longer a relevant distinction for traversal. We also decided to drop the existing
`counter`-scaled budget check (which made the same node Capped or not depending on unrelated
traversal pressure elsewhere in the same build, producing inconsistent graphs for the same node
across different requests) in favour of a separate, explicitly-named whole-graph limit — a
**Traversal Budget** — distinct from per-node Capping.

## Considered options

- **Overlap-aware Capping** — decide "too large to follow" based on overlapping memberships at
  time of traversal (e.g. a 2-founder startup should be followed; the same company at 1000
  employees should not) rather than raw `nodes_count`. Rejected for the first implementation: the
  overlap check (`Membership#overlapping`) is expensive to compute per-edge and currently has an
  unrelated NULL-handling bug (see `docs/backlog/membership-overlapping-null-handling-bug.md`).
  Noted as the more precise long-term answer; deferred deliberately, not ruled out.
- **User-selectable depth** — considered making traversal depth itself configurable per request.
  Deferred: kept the existing fixed cache depth (4) and will instead let the view slice the
  already-cached, depth-tagged `consolidated_descendents` down to a smaller depth — a read-side
  change with no traversal/cache impact. Requesting depths *beyond* the cached max remains an open,
  undecided question (`docs/backlog/user-selectable-graph-depth.md`).

## Consequences

- Cached payloads (`cached_data`) will grow, since previously-invisible large-group edges are now
  included as leaves — this compounds the standing size concern in
  `docs/backlog/cached-data-json-column-size.md` and is the reason a separate Traversal Budget
  ceiling was kept rather than relying on per-node Capping alone to bound payload size.
  `MAX_NODE_COUNT_TO_FOLLOW` is being renamed to reflect that it now gates expansion, not
  visibility.
- This ADR covers Group/Person **membership** traversal only. `Person#nodes` does not currently
  include `Transfer` edges at all (see `docs/backlog/transfer-edges-not-counted-as-graph-degree.md`)
  — transfers are rendered through a separate, non-traversed path (`consolidated_transfers`).
  Whether/how Capped and Traversal Budget extend to transfer edges is an open decision to revisit
  once transfers become real queueable graph edges; this ADR does not resolve it.
