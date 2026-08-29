# `Tag` is used for two different things, but `CanAddToQueue` treats them identically

**File:** `app/services/can_add_to_queue.rb`

```ruby
return false if next_node.nodes_count > Constants::MAX_NODE_COUNT_TO_FOLLOW
return false if counter * next_node.nodes_count > Constants::MAX_NODE_COUNT_TO_FOLLOW
return false if next_node.is_tag?
```

**Context:** `Tag` (`Group` STI subclass) is currently overloaded to mean two different things:

1. **Category/label tags** — Banking, Charities, Lobbyists. A classification bucket, not a
   real-world relationship. Correctly excluded from traversal — though the `nodes_count` size
   checks above already catch these on their own (they're large), making the blanket `is_tag?`
   check partly redundant here.
2. **Structural/affiliation tags** — e.g. Liberal/National Coalition. A real organisational
   relationship (which party a state branch is aligned with) that happens to be modelled as a
   `Tag` rather than a plain `Group`, typically with a small number of members.

The unconditional `next_node.is_tag?` check excludes both kinds equally. For (2) this is wrong:
these are small enough to pass the size checks and represent exactly the kind of relationship the
graph exists to show, but they're never followed in either direction. Confirmed via screenshots:
a root node that is itself a Tag ends up disconnected/orphaned in the render because no child can
ever traverse an edge back to it, and a plain-Group node's real parent affiliation (e.g. WA
Liberals → Liberal/National Coalition) never appears on its graph at all.

**Open question (unresolved as of 2026-08-28):** there is currently no data-level distinction
between the two kinds of Tag — nothing on the `Tag`/`Group` model marks "category label" vs
"structural affiliation." Also unresolved: whether, when reversing/traversing the graph, the code
even needs to know which kind of Tag it's looking at, or whether a different rule (e.g. size alone,
without the separate `is_tag?` check) would resolve both cases without needing a new field.

**Fix:** not yet decided. Options to weigh next session:
- Add a distinguishing attribute (e.g. a `category`/`affiliation` sub-type, or a boolean) so
  `CanAddToQueue` can treat them differently.
- Or drop the blanket `is_tag?` check entirely and rely on the existing `nodes_count` size checks,
  if that alone would correctly separate the two cases in practice (needs checking against real
  tag sizes in production — are all category-label tags reliably above `MAX_NODE_COUNT_TO_FOLLOW`
  and all affiliation tags reliably below it?).
