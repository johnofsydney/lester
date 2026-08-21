# Coding standards

This is a solo project, so the codebase itself is the standard for anything not listed here. This
doc exists to record conventions that aren't obvious from reading nearby code (naming quirks,
hard-won lessons, deliberate deviations from Rails defaults), so `/code-review`'s Standards axis
has something firmer than "smell" to check against.

Keep this doc short. Add an entry only when a convention has caused a real correction (a PR
comment, a rework) or a stated preference on record — not as a preemptive style guide.

## Ruby / Rails

- **Hash literals**: always write `{ key: key }` in full — never the `{ key: }` shorthand.
- **Keyword arguments in method calls**: always use the `foo(key:)` shorthand over `foo(key: key)`
  wherever the bareword matches, including for private method calls.
- **`attr_reader` over bare `@ivar` access**: declare `attr_reader :foo` and refer to `foo` rather
  than `@foo` within the class. Reserve direct `@ivar` access for the initializer assignment (and
  writer methods where a plain reader doesn't fit).
- **Prefer a method over an intermediate local variable**, including for a value only used once
  within a single method — i.e. don't stash a chain result in a local var when a private method
  reads just as well from the call site:

  ```ruby
  # preferred
  puts total

  def total
    items.sum(&:price)
  end

  # avoid
  total = items.sum(&:price)
  puts total
  ```

  Where the underlying computation is non-trivial or gets called more than once, memoize it —
  `def total; @total ||= items.sum(&:price); end` — rather than reaching for a local var to dodge
  recomputation. See `app/services/au_aec_donations/record_individual_transaction.rb`'s `donation`
  method for the pattern at scale: `donation`, `donor`, `recipient`, `transfer` are all memoized
  methods threaded through `call`/`valid?` rather than locals passed around.

  A local variable still wins when the value doesn't stand alone conceptually outside that one call
  site — it isn't a concept worth naming as a method on the class, just a step in one calculation.
- **`tap` over a name-it-then-return-it local variable**: when a method needs to perform a
  side-effect on a value and then return that same value, use `tap` instead of assigning it to a
  local var just to mutate it and return it:

  ```ruby
  # preferred
  def person
    People::RecordPerson
      .call(terms.last['full_name'], open_australia_id: person_id)
      .tap do |person|
        person.update!(open_australia_data: terms, open_australia_data_fetched_at: Time.current)
      end
  end

  # avoid
  def person
    person = People::RecordPerson.call(terms.last['full_name'], open_australia_id: person_id)
    person.update!(open_australia_data: terms, open_australia_data_fetched_at: Time.current)
    person
  end
  ```
- **Hardcoded IDs over name lookups**: where a record's identity is stable and its name is
  user-editable (e.g. `Group.charities_tag` → id 124513), prefer a hardcoded DB id constant over a
  `find_by(name: ...)` lookup. The DB is never recreated from scratch, so ids are safe to pin; names
  drift.
- **Never edit an already-run migration file**, even for comment-only changes. Migrations are an
  immutable record of what actually ran. Fix forward with a new migration instead.
- **Service objects expose `def self.call(...)`** that just does `new(...).call` — a uniform,
  stateless entry point (`Foo.call(...)`) while still using instance state internally for
  memoization. See `app/services/people/record_person.rb:13-15`,
  `app/services/record_transfer.rb:13-15`, `app/services/groups/record_group.rb:12-14`.
- **Two-tier `attr_reader`**: declare `attr_reader` for constructor-assigned ivars immediately under
  the class opening (before `initialize`), and a second `attr_reader` for memoized/derived values
  right after `private`. This keeps the "given to me" state visibly separate from "computed
  internally" state. See `app/services/people/record_person.rb:4` (public) and `:27-29` (private),
  `app/services/groups/record_group.rb:2` and `:35-37`.
- **Local, undecorated error classes**: a bare `StandardError` subclass, no module nesting, named
  `<Noun>Error`, declared at the very top of the file that raises it. Errors are local and
  documented by proximity rather than centralized in an `errors.rb`. See
  `app/services/tender_ingestor.rb:1-2` (`ValidationError`, `ApiServerError`),
  `app/services/aus_tender/scrape_single_contract_amendment.rb:1-3`.
- **Scopes vs class methods on ActiveRecord models**: composable query logic goes in
  `scope :name, -> { ... }`; `def self.x` is reserved for methods that return a single
  record/value or do non-relation work (e.g. `find_by_name_i`, `summarise_for`). Keeps scopes
  chainable and gives a clear division of labour. See `app/models/group.rb:93-135` (10 scopes)
  against its non-relation `self.` methods.
- **Single quotes by default**; double quotes only when interpolating or when the string contains
  an apostrophe. Rubocop-enforced, but worth stating alongside the other quoting-adjacent rules
  above.

### Not hard rules — lean this way, don't block on it

- **`def self.x` over `class << self`** for singleton methods — near-universal in this codebase
  (e.g. `app/models/group.rb:158-226`), but a `class << self` block isn't a defect if it's already
  there or genuinely clearer for a batch of methods sharing visibility modifiers.
- **Guard-clause chains over nested conditionals**, even for a long sequence of business rules —
  read as an ordered rule table rather than nested `if/elsif`. See
  `app/services/record_donation.rb:37-58`, `app/services/people/record_person.rb:71-98`. Don't force
  a genuinely branchy decision tree into an unnatural flat shape just to match this.

### Sidekiq jobs

- **Always `include Sidekiq::Job`** (never the legacy `Sidekiq::Worker` module) as the first line of
  the class body. Universal across `app/sidekiq/**`.
- **`sidekiq_options(lock: :until_executed, on_conflict: :log, ...)`** on any job that writes data or
  could plausibly be double-enqueued — an idempotency guard, not just boilerplate. See
  `app/sidekiq/au_aec_donations/import_donation_row_job.rb:4-8`,
  `app/sidekiq/cache/build_person_cached_data_job.rb:4`.

### Post-deployment tasks

- **Always the `maintenance_tasks` gem, never a plain `lib/tasks/*.rake` task.** A one-off
  backfill/cleanup/migration meant to run in production after a deploy belongs in
  `app/tasks/maintenance/*_task.rb` as a `MaintenanceTasks::Task` subclass, run from the
  `/maintenance_tasks` route — not a rake task run from the console. The gem gives pause/cancel/resume,
  run history, and a UI for free; a rake task throws all of that away. `lib/tasks/*.rake` stays fine
  for genuinely dev/local-only helpers that are never meant to run against prod. See
  `app/tasks/maintenance/dedupe_lobbyist_people_task.rb` and
  `app/tasks/maintenance/cleanup_orphaned_memberships_task.rb` for the shape: `attribute :dry_run,
  :boolean, default: true`, `collection`, `count`, `process`.
- **Consider, don't default to, an async job per item when `process` fans out.** If a task's
  `process(item)` would trigger meaningfully expensive or external per-item work, weigh enqueuing a
  Sidekiq job per item (for retry/backoff/spacing — see
  `app/tasks/maintenance/backfill_vic_council_election_results_task.rb`) against doing the work
  inline. Inline is the right call when the per-item work is cheap and has no external calls (e.g.
  `cleanup_orphaned_memberships_task.rb`'s in-process `delete`) — this isn't a hard rule in either
  direction, just a question worth asking per task.

## Testing

- **API client wrapper specs**: a wrapper class around an external API (AEC, ACNC, AusTender, ABN
  Lookup, etc.) needs a spec that exercises the real method with only the transport layer stubbed
  (e.g. `WebMock`/VCR at the HTTP boundary) — not just consumer specs that stub the whole client.
  Consumer-only stubs don't catch a broken wrapper.
- **Stub background job enqueues**: if the code under test enqueues a job (`.perform_async`,
  `.perform_later`, etc.), the spec must stub it — e.g. `allow(SomeJob).to receive(:perform_async)`
  — rather than letting a real call through. Real enqueues need a live Redis connection, which
  neither local dev nor CI provisions for the test suite; an unstubbed enqueue fails with
  `RedisClient::CannotConnectError` and is a CI-blocking bug, not flakiness.
  - Stub the specific job class(es) the exercised path actually triggers — don't blanket-stub
    Sidekiq globally, since that hides genuinely missing coverage.
  - Trace indirect enqueues, not just direct ones: a service call can fan out into a job enqueue
    several layers down (e.g. `Person#merge!` → `Nodes::Merge` → `Cache::BuildPersonCachedDataJob.perform_async`,
    or `Groups::RecordGroup.call` on a brand-new business-numbered Group →
    `Abn::UpdateGroupNamesJob.perform_async`). Read the full call path before assuming no job fires
    — the same code path can be safe or CI-blocking depending on which branch the fixture data
    happens to hit.
  - Where relevant, assert on the stub (`have_received(:perform_async).with(...)`) rather than just
    silencing it, so the enqueue itself stays covered.
  - Applies to both real `Sidekiq::Job` classes calling `.perform_async` directly and ActiveJob-based
    jobs routed through the sidekiq queue adapter.
- **Stub-then-assert idiom**: stub a collaborator/job with `allow(...).to receive(...)` in a
  `before` block, then assert on it later with `have_received(...).with(...)` — not an inline
  `expect(...).to receive(...)` at the point of the call. Keeps the "this gets called" assertion
  next to the rest of the example's assertions instead of interleaved with setup. See
  `spec/services/nodes/merge_spec.rb:15-16,33`, `spec/services/groups/record_group_spec.rb:11,92`.
- **RSpec `type:` metadata by directory**: tag the top-level `describe` with `type: :service` for
  everything under `app/services/` (and `app/mappings/`), `type: :job` for everything under
  `app/sidekiq/`. Model specs get no `type:` tag. See
  `spec/services/people/record_person_spec.rb:4`, `spec/sidekiq/councils/nsw/import_council_result_row_job_spec.rb:3`.

## Docs

One root, `docs/`, with five purpose-specific subfolders. See
`docs/plans/0001-docs-folder-taxonomy.md` for the full reasoning behind this split. `notes/`'s
former contents have been migrated into this structure.

- **`docs/adr/`** — a settled decision record: short, past-tense, "we chose X over Y because Z."
  `NNNN-slug.md`, sequential number. Carries a `Status:` line (`Accepted` / `Superseded by
  ADR-NNNN`). Immutable once merged to main — see the numbering rule below for what "immutable"
  means in practice.
- **`docs/plans/`** — a detailed, forward-looking design/build doc for committed work. `NNNN-slug.md`,
  sequential number (its own counter, separate from `adr/`). Carries a `Status:` line (`Proposed` /
  `In Progress` / `Implemented`). Kept permanently as a historical record, even once implemented —
  never deleted.
- **`docs/backlog/`** — one file per not-yet-committed idea or future-work item. `slug.md`, no
  number — numbers are reserved for committed work. Deleted once promoted to a numbered plan or a
  GitHub issue; the promoted artifact becomes the record.
- **`docs/runbooks/`** — operational "what do I do when X happens" procedures. `slug.md`, no
  number, no status field. A living document, edited in place as the procedure changes.
- **`docs/agents/`** — process docs read by Claude/skills (existing, unchanged). `slug.md`, no
  number.

`CONTEXT.md` stays at the repo root — see `docs/agents/domain.md` for how it and `docs/adr/` fit
into exploration.

**Numbering + clash resolution** (shared by `adr/` and `plans/`): next number is the highest
existing `NNNN` in that folder + 1, zero-padded to 4 digits. A number is only "claimed" once its
file is merged to main. If two branches independently claim the same number, whichever merges
second renumbers its file (and any cross-references) to the next free number before merging —
never renumber a file already on main, same spirit as never editing an already-run migration.

## Git / PRs

- **No squash merges** — always merge with a real merge commit. Accurate history matters more than
  a tidy log.
- Don't commit unless explicitly asked, even mid-task.
