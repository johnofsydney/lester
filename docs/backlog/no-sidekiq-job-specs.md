# Zero specs for any Sidekiq job

There are ~29 jobs across `app/sidekiq/` and zero corresponding specs. No regression protection
for: all cache rebuild jobs, all AusTender ingestion jobs, all AuLobbyists jobs, transfer refresh
jobs, ABN jobs.

**Fix:** Prioritise specs for the highest-risk jobs first — `BuildPersonCachedDataJob`,
`BuildGroupCachedDataJob`, the AEC ingestion jobs. Use a real test DB (not mocks) — see
`CODING_STANDARDS.md`'s stub-job-enqueues rule and the project history behind it.
