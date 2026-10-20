# No proactive mechanism refreshes stale `cached_data`/exports it to S3

**Files:** `app/sidekiq/cache/refresh_cached_data_job.rb`, `app/models/concerns/cached_methods.rb`
(`cache_stale` scope), `app/sidekiq/exports/upload_key_contents_job.rb`

**Context:** since PR #393, every `Person`/`Group` export to the `join-the-dots-exports` S3 bucket
happens purely as a side effect of `CachedMethods#refresh_cached_data!` being called — from a live
page visit, `Nodes::Merge`, an admin action, or a maintenance dedupe task. There is no scheduled
job that proactively sweeps the tables for stale/never-built `cached_data`. A node nobody has ever
visited, merged, or touched never gets exported at all.

`Person.cache_stale`/`Group.cache_stale` (`app/models/concerns/cached_methods.rb:15-17`) already
exists for exactly this — a SQL-level scope over the real `cached_summary_timestamp` column — but
has no caller anywhere in the app. It was kept deliberately (not deleted alongside the job that
used to call it) because this was always the planned next step.

**Fix:** not yet built. An earlier attempt existed as a self-rescheduling cursor job
(`Exports::BuildFlattenedExportJob`, modeled on `Cache::RefreshNodesCountJob`'s pattern — process a
bounded batch of `cache_stale` records, call the per-record refresh, re-enqueue itself for the next
batch until exhausted) but was deleted when scope was deliberately cut back to "export only on
refresh" during the same PR. See PR #393's history for that shape if reviving a cursor-based
sweep; the per-record logic it would call (`refresh_cached_data!(queue: :low)`) hasn't changed.
