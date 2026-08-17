# Dead code in `BuildQueue#can_add_to_queue?` obscures the real algorithm

**File:** `app/services/build_queue.rb:34-79`

```ruby
def can_add_to_queue?(node, next_node)
  return CanAddToQueue.call(node, next_node, counter)   # ← returns here always

  # unreachable code - leaving in place for later cherry picking
  if counter > 200
    raise 'Counter exceeded'
    ...
  end
end
```

Everything from line 37 to line 79 is unreachable. The comment says "leaving in place for later
cherry picking" — that's what git history is for. Sitting inert in a production file it makes the
actual traversal logic (four lines, just `CanAddToQueue.call`) harder to find and misleads readers
into thinking there's complexity here that doesn't exist.

**Fix:** Delete lines 37-79. If the alternative algorithm is worth keeping as a reference, it's in
git history — no need to keep it inline.
