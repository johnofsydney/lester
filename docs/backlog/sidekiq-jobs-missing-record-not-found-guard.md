# Sidekiq jobs call `.find(id)` with no `RecordNotFound` guard

**Files:**
- `app/sidekiq/cache/node_count_job.rb:13`
- `app/sidekiq/transfers/refresh_single_transfer_amount_job.rb:12`
- `app/sidekiq/acnc/ingest_single_charity_people_job.rb`
- `app/sidekiq/abn/update_group_names_job.rb`

If a record is deleted between enqueue and execution, Sidekiq retries forever (default 25 attempts
over 21 days) then dead-letters the job.

**Fix:** Use `find_by` and return early instead of `find`:

```ruby
def perform(id)
  record = Person.find_by(id:)
  return unless record
  # ...
end
```
