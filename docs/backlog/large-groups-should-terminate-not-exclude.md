**Status: implemented on `handle-graph-better` (2026-08-29).** `CanAddToQueue`/`BuildQueue` now
follow this design — see ADR 0007. Remaining open item on this page: the deferred visual-weight
question at the bottom.

# Large/tag groups should appear as terminal leaves, not be excluded from the graph entirely

**File:** `app/services/can_add_to_queue.rb`, `app/services/build_queue.rb`

**Context:** `CanAddToQueue` currently conflates two distinct decisions into one boolean:

1. Should this node **appear** in the graph at all (as an edge from its parent)?
2. Should this node be **expanded further** (added to the queue so its own members get traversed)?

Both `next_node.nodes_count > MAX_NODE_COUNT_TO_FOLLOW` and `next_node.is_tag?` currently gate
entry into the queue — meaning a large group (a party with hundreds of members, a federal
parliament tag) is invisible on the graph entirely, not just un-expanded.

**Example (screenshots, 2026-08-28):** The Hills Shire Council graph shows all ~17 councillors at
depth 1, correctly. But each councillor's party (Liberals (NSW), ALP (NSW)) is completely absent —
confirmed via each councillor's own page, which lists their party membership fine, just not on the
council's graph. Two councillors sharing a party, or being on opposite parties, is exactly the kind
of "gripped together" relationship this graph exists to show, and currently can't be seen at all
because the party node doesn't get shown, let alone followed further.

**Desired behaviour:** show the edge from councillor → party (the party appears as a depth-2 leaf
node), but do not enqueue the party for further expansion to its other members — don't follow
councillor → party → hundreds of unrelated other party members. This generalises past `is_tag?`:
any node whose membership is very large should behave this way, tag or not, so the special-cased
`is_tag?` exclusion becomes unnecessary — replaced by a single "can expand from here" size check
applied only when deciding whether to enqueue, not when deciding whether to draw the edge.

**Relationship to other backlog items:** this supersedes/subsumes
[[tag-blocks-structural-affiliations-from-traversal]] — if large groups always show as leaves
regardless of type, the Tag-vs-plain-Group distinction may not be needed at all (matches the user's
own instinct that membership size, not category, should drive the rule).

**Fix:** not yet designed. Needs `BuildQueue`/`CanAddToQueue` reworked so the queue-filter (expand)
and the node/edge-inclusion (display) are two separate checks rather than one, and depth-limiting
of the *edge itself* is preserved (e.g. via `consolidated_descendents(depth: 4)`) so terminal leaves
still respect existing depth caps.

**First implementation: plain `nodes_count` size check, not overlap-aware.** The Capped threshold
decides "too large to bother following through" using total `nodes_count`, the same static,
cheap check used today — deliberately *not* scoped to overlapping memberships (see [[membership-overlapping-null-handling-bug]]), even though overlap would be the more precise answer. Reasoning:
overlap is a per-pair, per-edge computation — mixing it into a group-level "is this too big to
expand" check would make the same group Capped for one starting node and not for another, which
breaks the size check's simplicity and the caching model. Concrete case to remember: a 2-founder
startup should be followed through (they clearly overlapped and the connection is meaningful); the
same company at 1000 employees should not — overlap-awareness would get this right in both cases,
a pure size check gets the second case right but may wrongly cap small-but-real early-stage
overlaps if `nodes_count` alone (counting people who joined *later* too) pushes it over the
threshold. Deliberately deferred: the overlap check is expensive and out of scope for the first
implementation.

**Decided: depth/colour unaffected by Capped status.** A Capped node sits at its normal depth and
gets the normal depth-based colour (`Descendent#color`) — being Capped only changes the
expand/don't-expand decision, not where it sits on the depth ladder. Any Capped-specific visual
cue belongs with the open mass/size question below, not with colour/depth.

**Decided: single fixed size constant, not traversal-budget-scaled.** Drop the current dead
`counter * next_node.nodes_count > MAX_NODE_COUNT_TO_FOLLOW` multiplication entirely — Capped is a
per-node judgement ("is this group too big to represent a meaningful connection"), not a global
traversal-budget concern. Scaling by `counter` would make the same group Capped in one traversal
and not another purely due to unrelated traversal pressure elsewhere, making the graph
inconsistent between requests for the same node. If a separate global performance/budget cap is
still needed, it should be an explicit, distinct limit — not blended into the Capped decision.

**Decided: Capped applies uniformly to any node type, not just Group.** A Person with an unusually
large number of connections (e.g. hundreds of small individual transfers) is exactly as unhelpful
to expand through as a large Group, for the same reason — the check is on `nodes_count` regardless
of Person vs Group, no type-based special-casing.

**Decided: scoped to membership traversal only, transfers explicitly out of scope for now.**
`Person#nodes` (`app/models/person.rb:52`) returns only `groups` — transfers are never queued or
expanded via `BuildQueue`/`CanAddToQueue` at all (they're rendered through a separate path,
`consolidated_transfers`/`money_in`/`money_out` in `to_h`). Capped, as a traversal-expansion
concept, can't apply to transfer edges until that foundational gap is closed — see
`docs/backlog/transfer-edges-not-counted-as-graph-degree.md`. This Capped design covers Group/Person
membership traversal only. Keep the long-term goal in mind when implementing (design so the same
Capped concept can extend to transfer edges later), but do not expand scope now to include them.

**Decided: keep threshold at 50, rename the constant.** `Constants::MAX_NODE_COUNT_TO_FOLLOW` (and
the duplicate dead `BuildQueue::MAX_GROUP_SIZE_TO_FOLLOW`) stays at `50` — the number itself is a
separate, empirical tuning decision to make once Capped is live and real graphs can be observed,
not something to guess at now. Rename the constant to reflect its new meaning: it now gates
*expansion*, not *visibility* (e.g. `MAX_NODES_TO_EXPAND`).

**Decided: keep a separate, explicit total-node/payload cap, distinct from per-node Capping.**
Capping bounds fan-out at any single node, but doesn't bound the *sum* across many Capped leaves —
e.g. a node with 40 direct connections, each just under the 50-member Capped threshold, still adds
40 new leaf nodes to the payload that were previously silently dropped entirely (before Capped
existed, they were invisible; now they're shown). Combined with the standing
[[cached-data-json-column-size]] concern, this should be a conscious, separate, explicitly-named
ceiling on total traversal size — not an unstated assumption that per-node Capping alone keeps
payloads bounded.

**Decided: name the total-cap mechanism "Traversal Budget"**, distinct from "Capped" (per-node) —
the whole-graph-build stops adding nodes once the Traversal Budget is exhausted. **Implemented**:
this mechanism already existed as `Constants::MAX_DESCENDENTS_RESULTS` in
`consolidated_descendents` — renamed to `Constants::TRAVERSAL_BUDGET`, no new logic needed.

**Open design option to preserve, not yet decided:** whether a terminal leaf's visual weight
(`Descendent#mass`/`size`, currently driven by `parent_size`/`nodes_count`) should signal "this is
a large group, that's why traversal stopped here," versus rendering identically to any other leaf.
Don't foreclose this when implementing — keep the size data available to `Descendent` so the
option can be switched on later without re-plumbing.
