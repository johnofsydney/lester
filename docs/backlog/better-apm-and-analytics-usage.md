# New Relic and Google Analytics are set up but barely used

Both tools are wired in but only at the shallowest "default install" level, so neither is earning
its keep. Raised in #320.

## New Relic (APM / Logs / Errors)

Current state (`config/newrelic.yml`): stock agent config — auto-instrumentation, distributed
tracing, and log forwarding are all on, but nothing is customised. The only manual touch points in
the codebase are a handful of `NewRelic::Agent.notice_error` calls (`app/sidekiq/cache/build_person_cached_data_job.rb`,
`app/sidekiq/cache/build_group_cached_data_job.rb`, `app/models/transfer.rb`,
`app/services/abn/group_name_updater.rb`, `app/services/groups/record_group.rb`,
`app/services/people/record_person.rb`) — scattered, inconsistent (two of them pass a bare string
instead of an `Exception`, which New Relic accepts but loses a real backtrace), and there's no
custom instrumentation, no custom events/metrics, and no dashboards.

Given this app's actual pain points are Sidekiq-heavy ingestion jobs (AEC, ACNC, AusTender,
OpenAustralia, lobbyist register) and the weekly cache rebuild path (`BuildQueue`,
`BuildPersonCachedDataJob`/`BuildGroupCachedDataJob`), the highest-value New Relic work is
probably:

- Custom instrumentation / custom events around each ingestion job (records processed, records
  skipped/disambiguation-failed, duration) so ingestion health is visible without reading Sidekiq
  logs by hand.
- A consistent error-reporting convention (always pass the `Exception`, not a string; a shared
  helper so the `if defined?(NewRelic)` guard isn't repeated ad hoc) — see the existing
  `record_group.rb`/`record_person.rb` "Cannot Disambiguate" calls as the pattern to fix first.
- "Hooked into Claude" (per the issue title) most likely means giving Claude Code direct query
  access to New Relic data during debugging/triage — New Relic publishes an MCP server for this.
  Worth a research spike on its own before committing to it.

## Google Analytics

Current state: a bare GA4 `gtag.js` snippet duplicated in both `app/views/layouts/application.html.erb`
and `app/views/layouts/widescreen.html.erb`, tracking default pageviews only — no custom events, no
goals/conversions configured. This PR fixed two small correctness issues (stray leftover
`console.log("Google Tag Manager is working")` debug line, and the tag firing in every environment
including development/staging — the latter meaning local/staging traffic has likely been polluting
the production GA4 property's numbers).

The reason "not sure what it is telling us" is basically that nothing beyond raw pageviews is being
captured. To make GA answer real questions, need to decide what matters for a transparency-tool
site — e.g. network-graph searches performed, entity pages viewed (person vs group), donation/
contract detail views — and add explicit `gtag('event', ...)` calls at those points. That's a
product decision (what to track) more than a code change, hence not done as part of this ticket.

## Why not done now

Both items need a scoping/design decision (what New Relic custom events matter, whether to adopt
New Relic's Claude/MCP integration, what GA events are worth tracking) rather than being a
drop-in fix — the two safe, unambiguous fixes (dead debug log, GA tag leaking into non-prod
environments) were applied directly instead of deferred here.
