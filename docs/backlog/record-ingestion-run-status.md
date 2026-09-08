# No visibility into recent ingestion success/failure

Admins can jump to Sidekiq and Maintenance Tasks (see the Dashboard action items) to inspect job
state, but there's no purpose-built summary of "did each ingestion source run successfully
recently?" — AEC donations, ACNC charities, AusTender contracts, lobbyist register, ABN lookup,
OpenAustralia. Answering that today means cross-referencing Sidekiq's job history with
sidekiq-scheduler's cron config by hand.

**Fix:** Introduce a lightweight run-log (e.g. an `IngestionRun` record with source, started_at,
finished_at, status, error) written by each top-level ingestion job on completion/failure, and
surface it as an ActiveAdmin panel — most recent run per source, with a red/green status. Scope
carefully: this is a reporting layer on top of existing jobs, not a job-framework replacement.
