# N+1 queries in `NodeMethods#name_for_bar_graph` (hot path for every cache build)

**File:** `app/models/concerns/node_methods.rb:116-125`

```ruby
def name_for_bar_graph(key)
  # TODO: refactor out the fetching from the db. This is inefficient.
  klass = key[1].constantize
  instance = klass.find(key[0])  # ← one query per counterparty
  name = instance.name
  ...
end
```

`all_the_groups` calls this via `transform_keys` on the result of a `.group().sum()` query. For a
node with, say, 40 distinct transfer counterparties, that's 40 individual `find` queries just to
build chart labels — for large political parties (ALP, Liberals) this runs against hundreds of
counterparties, and it's called inside `to_h`, which every cache build job hits.

**Fix:** Collect all `[id, type]` keys first, batch-load names with
`Person.where(id: ...).pluck(:id, :name)` and `Group.where(id: ...).pluck(:id, :name)`, build a
lookup hash, then transform without hitting the DB per record.
