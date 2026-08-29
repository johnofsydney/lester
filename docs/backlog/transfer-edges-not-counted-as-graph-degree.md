# Transfer edges aren't given equal weight to membership edges in the relationship graph

**Context:** the graph's intent is that a 2nd-degree connection reached via a `Transfer`
("donated to") should count exactly the same as one reached via a `Membership` ("member of") —
i.e. degree/depth should be edge-type-agnostic. This is not implemented today: the traversal
(`BuildQueue`, `CanAddToQueue`, `Descendent`) needs to be checked against this intent and
reconciled if it currently treats the two edge types asymmetrically (e.g. different depth
increments, different follow limits, or one edge type not expanded at all beyond a certain point).

**Fix:** audit `BuildQueue`/`CanAddToQueue`/`Descendent` for where membership vs transfer traversal
diverges, and bring transfer-edge traversal to parity with membership-edge traversal for degree
counting.
