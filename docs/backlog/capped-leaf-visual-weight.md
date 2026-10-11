# Should a Capped leaf's visual weight signal why traversal stopped there?

**Files:** `app/models/descendent.rb` (`#mass`, `#size`)

**Context:** open design option preserved from the Capped-node work (ADR 0012). A Capped leaf
currently renders identically to any other leaf — normal depth-based colour, normal
`parent_size`/`nodes_count`-driven mass and size. The open question is whether its visual weight
should instead signal "this is a large group, that's why traversal stopped here", so a viewer can
distinguish a Capped party from an ordinary small leaf.

**Constraint:** the size data (`nodes_count`) is already available to `Descendent`, so the option
can be switched on without re-plumbing traversal or the cache. Decided earlier: depth/colour stay
unaffected by Capped status — any Capped-specific cue belongs in mass/size/shape, not colour.

**Fix:** not yet decided. Needs a look at real rendered graphs (e.g. a council with several
Capped parties) to judge whether the ambiguity actually confuses anyone before adding a cue.
