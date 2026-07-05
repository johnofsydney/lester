# Top 5 Improvement Candidates

## 1. `RecordPersonOrGroup` — the regex classifier is a maintenance trap

**File:** `app/services/record_person_or_group.rb`

The `person_or_group` method is 130 lines of sequentially-checked regex patterns with no structure. Several concrete problems:

- `regex_for_company_words_13` and `regex_for_company_words_14` are **identical** — same pattern, same comment. One of them is doing nothing.
- `regex_for_specific_companies_1` and `regex_for_campaign_words_3` are also identical.
- The word "Constitutional" is misspelled as "Constituional" in two of the patterns, meaning it never matches.
- There's no way to test or explain which pattern classified a given name — if a donor is misclassified as person vs group, you can't easily debug it.
- The ordering matters (it returns on first match) but the ordering is not documented and hard to reason about.

**Suggested approach:** Consolidate the ~14 company-word patterns into a single combined regex (they're all doing the same thing). Extract the specific-name overrides into a constant array. Add a debug mode that reports which rule matched. Fix the typos. Delete the two dead duplicate patterns.

This is mission-critical code — misclassification corrupts the entire donation dataset.

---

## 2. N+1 queries in `NodeMethods#name_for_bar_graph` (hot path for every cache build)

**File:** `app/models/concerns/node_methods.rb`, line 116-125

```ruby
def name_for_bar_graph(key)
  # TODO: refactor out the fetching from the db. This is inefficient.
  klass = key[1].constantize
  instance = klass.find(key[0])  # ← one query per counterparty
  name = instance.name
  ...
end
```

`all_the_groups` calls `name_for_bar_graph` via `transform_keys` on the result of a `.group().sum()` query. For a node with, say, 40 distinct transfer counterparties, that's 40 individual `find` queries just to build the chart labels. For political parties (ALP, Liberals etc.) this runs against hundreds of counterparties.

This is called inside `to_h`, which is called by every cache build job. The TODO comment acknowledges the problem but it hasn't been fixed.

**Fix:** Collect all the `[id, type]` keys first, batch-load names with `Person.where(id: ...).pluck(:id, :name)` and `Group.where(id: ...).pluck(:id, :name)`, build a lookup hash, then do the transform without hitting the DB per record. Single pass, two queries instead of N queries.

---

## 3. Hardcoded tag IDs in `Group` — will silently break in any fresh DB

**File:** `app/models/group.rb`, lines 214-227

```ruby
def self.charities_tag        = Group.find(124_513)
def self.lobbyists_tag        = Group.find(124_509)
def self.client_of_lobbyists_tag = Group.find(124_510)
def self.government_department_tag = Group.find(124_514)
```

These are called from scopes, jobs, and admin actions throughout the app. In production they work fine. But:

- In a fresh development DB or a restored staging snapshot with a different sequence, these raise `ActiveRecord::RecordNotFound` with no useful error message.
- There's no indication in the code what these IDs mean or how they were seeded.
- `Membership.charity_subgroups` and `Membership.person_in_charity` both call `Group.charities_tag.id` — if that returns nil, the scopes silently return wrong data.

**Fix:** Look up by name instead of ID, with memoization:

```ruby
def self.charities_tag
  @charities_tag ||= find_by!(name: 'Charities', type: 'Tag')
end
```

Add a seed or a guard that creates the tags if they don't exist. The `find_by!` will at least give a clear error message instead of a cryptic "Couldn't find Group with id=124513". The IDs themselves could then be dropped from the codebase entirely.

---

## 4. Dead code in `BuildQueue#can_add_to_queue?` obscures the real algorithm

**File:** `app/services/build_queue.rb`, lines 34-79

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

Everything from line 37 to line 79 is unreachable. The comment says "leaving in place for later cherry picking" — but that's what git history is for. The dead code is 40+ lines of an alternative traversal algorithm that is genuinely interesting and might be worth implementing one day, but sitting inert in a production file it:

- Makes the actual traversal logic (just `CanAddToQueue.call`) harder to find
- Misleads readers into thinking there's complexity here that doesn't exist
- Raises the question "is this intentionally dead, or did someone forget to remove the early return?" every time someone reads it

**Fix:** Delete lines 37-79. If the alternative algorithm is worth keeping as a reference, move it to a comment or design doc. The real behaviour is four lines in `CanAddToQueue`.

---

## 5. `Person` model: double `include`, dead OpenStruct code, and a dead assignment

**File:** `app/models/person.rb`

Three distinct issues that together make the most central model harder to trust:

**a) `ExternalIdentifiable` is included twice:**
```ruby
class Person < ApplicationRecord
  include ExternalIdentifiable   # line 6
  include ExternalIdentifiable   # line 14
```
Rails concerns are idempotent so it doesn't break anything, but it signals the file hasn't been reviewed carefully.

**b) `#transfers` is acknowledged dead:**
```ruby
def transfers
  # TODO: Potentially useless code
  OpenStruct.new(
    incoming: Transfer.where(taker: self), # always nil. replace with [] ?
    outgoing: Transfer.where(giver: self, giver_type: 'Person').order(amount: :desc)
  )
end
```
The comment says `incoming` is "always nil" and the method is "potentially useless". It's not called by any controller or view (only the cached path is used). If it's unused, delete it.

**c) Dead assignment in `#first_degree_transfers`:**
```ruby
def first_degree_transfers
  ...
  OpenStruct.new(
    in: number_to_currency(...),
    out: number_to_currency(...)
  )                                       # ← result assigned to nothing, immediately discarded

  return 'None' if incoming_transfers.empty? && outgoing_transfers.empty?
  ...
end
```
The `OpenStruct.new(...)` on line 123 is evaluated but its return value is never used — the next line begins the actual return logic. The OpenStruct does nothing. This was likely left over from an earlier version of the method.

**Fix:** Remove the duplicate include. Audit whether `transfers` and `first_degree_transfers` are called anywhere (a grep suggests they're only used by `tweet_body` which is itself only called from one controller action). If they are live, remove the dead assignment and the dead OpenStruct. If `transfers` is genuinely unused, delete it.
