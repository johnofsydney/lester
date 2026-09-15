# Some jobs swallow all StandardErrors, including retryable ones

Four jobs rescue `StandardError` broadly, log, and never re-raise — so a transient failure
(network blip, DB timeout) silently never retries, same as a permanent one:

- `app/sidekiq/cache/build_group_cached_data_job.rb:30-34`
- `app/sidekiq/cache/build_person_cached_data_job.rb:52-56`
- `app/sidekiq/aus_tender/ingest_contracts_url_job.rb:510-514` — comment literally says
  "optionally re-raise if you want retry"
- `app/sidekiq/linkedin/profile_getter_job.rb:1073-1075`

Per the permanent-vs-retryable pattern in `CODING_STANDARDS.md`'s "Sidekiq jobs" section, these
should split their rescue: permanent errors (e.g. `ActiveRecord::RecordNotFound`) swallowed as
today, transient errors re-raised so Sidekiq retries. `open_australia/ingest_person_job.rb` is a
good three-way template (rate-limit reraise, permanent API error swallow, StandardError reraise).

Not fixed alongside the narrower missing-rescue cleanup (`Cache::NodeCountJob`,
`Transfers::RefreshSingleTransferAmountJob`, `Abn::UpdateGroupNamesJob`) because splitting these
four is a real behavior change — previously-silent transient failures would start retrying — and
needs a deliberate look per job rather than a mechanical fix.
