# Ingest Federal Politicians — Design & Roadmap

**Status:** In Progress

## Current status (2026-07-19)

**Increment 1 — Ingest — is done and verified on staging.** See [issue #209](https://github.com/johnofsydney/lester/issues/209) (parent spec), [#210](https://github.com/johnofsydney/lester/issues/210) and [#211](https://github.com/johnofsydney/lester/issues/211) (implementation tickets).

What exists today:
- `OpenAustralia::ApiClient` — Faraday wrapper for `getRepresentative(id)`, `getSenator(id)`, `getRepresentatives`, `getSenators`.
- `OpenAustralia::IngestPerson.call(person_id:)` — fetches a person's full Term history from **both** chambers, merges chronologically, resolves/creates the `Person` via the existing `People::RecordPerson` name/external-identifier logic, and stores the raw merged Terms on `open_australia_data` (jsonb) / `open_australia_data_fetched_at` (timestamp) columns on `people`.
- `OpenAustralia::IngestCurrentPoliticians.call` — fetches the current roster (`getRepresentatives` + `getSenators`), enqueues one `IngestPersonJob` per distinct `person_id`.
- `open_australia_id` on `ExternalIdentifiable` / `People::RecordPerson`.

**Deliberately not done in Increment 1** (see `CONTEXT.md` and `docs/adr/`):
- No `Membership`/`Position` records are created — this is Ingest only, not Interpretation.
- Only *currently-serving* politicians are ingested (~226 people) — not the full 50-year historical set.
- No freshness/staleness checking, no throttling, no scheduled trigger — console-only, unconditional overwrite on each run.

Domain vocabulary (Term, Raw Terms, Ingest, Interpretation, Major/Minor Party, Federal/State Branch Membership, Office Holder, Current Standing) is defined in `CONTEXT.md`. Settled decisions are recorded in `docs/adr/0001`–`0005`. Read both before starting any of the work below — several non-obvious rules (e.g. a State Branch/Minor Party Membership only closes when a person's *next* distinct affiliation supersedes it, ADR-0005 — it's not simply "never closed", that was the original ADR-0002 rule before 0005 refined it) are already resolved there, don't re-derive them.

---

## Increment 2 — Interpretation (done, merged to main via #232)

Turn each Person's `open_australia_data` (their Raw Terms) into real `Membership`/`Position` records: one Parliament Membership per continuous stint, one Federal Branch Membership per major party (closed when the parliamentary term ends — ADR 0002), one State Branch / Minor Party Membership per party (never auto-closed — ADR 0002), with Office Holder terms (Speaker/Deputy-Speaker/President/Deputy-President) inheriting party from the preceding real-party Term (ADR 0003).

This is where essentially all the complexity from the first (abandoned) attempt lived. Progress so far:

- **Grouping Terms into continuous periods** — done, no DB writes. `OpenAustralia::Interpretation::ExtractPeriods` groups Terms into continuous Parliament periods (break on a real gap or a house change); `OpenAustralia::Interpretation::ResolvePartyAffiliations` separately groups into continuous party-affiliation periods (break on a real gap or a party-string change), with Office Holder Terms folded into the party they inherit per ADR-0003 before grouping — so the merge/lose-title bug in the old `group_into_stints` doesn't recur; it's structurally avoided rather than patched.
- **Federal vs State Branch vs Minor Party group resolution** — done. Major parties resolve directly against `Group::NAMES` via a small party-family classifier (not via `MapGroupNamesAecRecipients`'s synthetic-suffix trick — checked against Barnaby Joyce's real Queensland Senate data and found the mapper has no Nationals/QLD pattern, so that approach would have silently mis-resolved). Minor parties resolve via `MapGroupNamesAecRecipients` for its alias-cleanup rules. `MapElectorateToState` ported from the abandoned branch (pure data, unchanged) for MP electorate→state; Senators get state directly from the Term.
- **Party string audit** — done as part of the above; resolved against real data (Barnaby Joyce, Milton Dick) rather than a separate audit pass.
- **Idempotency** — not yet re-solved; see manual pre-step below, which sidesteps the hard version of this question for the first run.
- **The DB-writing step** — done. `OpenAustralia::Interpretation::RecordMembershipsAndPositions` creates/closes Parliament, Federal Branch (ADR-0002), and State/Minor Party Memberships and Positions (closed on supersession per ADR-0005, not left permanently open) from the two services above, and is idempotent on re-run (verified by spec, including a re-run-after-new-data-closes-a-period case).

Shipped via [#232](https://github.com/johnofsydney/lester/pull/232): two rake tasks in `lib/tasks/maintenance.rake` — `rake lester:cleanup_legacy_politician_memberships` (DRY_RUN=true by default, deletes the legacy bulk-import data below) and `rake lester:record_politician_memberships_and_positions` (runs `RecordMembershipsAndPositions` for every already-ingested politician). Deliberately console/rake-triggered only for this first run — no Sidekiq job chaining or scheduler entry — mirroring how Increment 1 itself first shipped. **That gap (no automatic trigger) is exactly what Increment 3 below picks up.**

### Manual pre-step required before running the DB-writing step

The ~226 current politicians already have a Membership in `Group.find(877)` ("australian federal parliament") and in their Federal Branch party group (e.g. `nationals (federal)`), from an earlier, cruder bulk import (352 people, all created Sept 2024–Mar 2025, no `evidence`, single always-open span per person — factually wrong for anyone with real history, e.g. Barnaby Joyce's existing row shows continuous "MP" since 2013 with no record of his 2005–2013 Senate service or his 2017 disqualification gap).

This new Interpretation work supersedes those. Before running the write step against real data, manually delete:
- All `Membership`/`Position` records where `group_id: 877` (the Parliament group)
- All `Membership`/`Position` records for people in Federal Branch party groups (`nationals (federal)`, `alp (federal)`, etc.)

With that clean slate, the write step can assume no pre-existing Parliament/Federal Branch data and use plain `find_or_create_by!` — no reconciliation logic needed. State Branch / Minor Party Memberships are unaffected either way (they're found by person+group only, never dated-closed, so the existing dateless rows get reused automatically regardless of this cleanup).

Suggest running this against the ~226 already-ingested current politicians as the test bed before touching historical data at all.

---

## Increment 3 — Scheduling & Automation

Increments 1 and 2 are both proven correct but only run when a human triggers them from a console/rake task. Two related gaps remain before the pipeline can keep itself current without manual intervention:

1. **Discover new politicians** — nothing re-fetches the current roster after the initial run, so anyone who enters Parliament later (by-election, new term) never gets ingested.
2. **Refresh already-known current politicians** — nothing re-fetches Raw Terms for politicians already in our DB, so an exit (retirement, lost seat, disqualification) or a mid-term party switch that OpenAustralia later records is never picked up, and their Parliament/Federal Branch Membership never closes.

Confirmed with the project owner: this ships as two PRs, and the two needs collapse into one scheduled job by the end of 3b (not two separate jobs).

### Increment 3a — done, shipped via [#238](https://github.com/johnofsydney/lester/pull/238)

- `OpenAustralia::IngestPersonJob#perform` now runs `OpenAustralia::Interpretation::RecordMembershipsAndPositions.call(person:)` right after a successful `IngestPerson.call` (guarded by `if person`, since `IngestPerson` returns `nil` when OpenAustralia has no terms for that `person_id`) — this is the "chain Interpretation onto Ingest" gap PR #232 deliberately left open.
- New `OpenAustralia::IngestCurrentPoliticiansJob` — thin `Sidekiq::Job` wrapper around the existing `OpenAustralia::IngestCurrentPoliticians` service, following `AuLobbyists::IngestLobbyistsJob`'s rescue/log/re-raise pattern.
- Scheduled monthly in `config/sidekiq.yml`, cron `'0 14 4 * *'` — lands at 00:00 AEST on the 5th (cron day is 4, not 5, because hour 14 UTC rolls into the next AEST day per the file's own conversion table; this is commented inline both in the cron entry and in `IngestPersonJob`). Day 5 was chosen to avoid the 1st/2nd, where ACNC/lobbyist/AusTender-backfill jobs already run.
- This alone covers need #1 (new politicians via the roster) and *most* of need #2 (anyone still on the roster gets refreshed) — but not the case where someone drops off the roster entirely. That's 3b.

### Increment 3b — done

Added the DB-side half of need #2: politicians who've left the roster entirely (retirement, lost seat, disqualification) and so were never re-ingested by 3a's roster-only job, even though our DB still shows them as current.

- New `Membership.person_currently_in_federal_parliament` scope — `Person` members with an open (`end_date: nil`) `Membership` in `Group.federal_parliament` (id 877), mirroring the existing `person_in_lobbyists`/`person_in_charity` scope pattern.
- `OpenAustralia::IngestCurrentPoliticians#person_ids` now unions `roster_person_ids` (unchanged, from the live API) with `db_current_person_ids` (`Person`s matching the new scope, mapped to `open_australia_id`, dropping anyone without one), deduped, before the existing per-id `IngestPersonJob.perform_async` fan-out — no change to the fan-out itself, each id still gets its own async job.
- No new Ingest or Interpretation logic needed — `IngestPersonJob` (as of 3a) already does ingest-then-interpret for whatever `person_id` it's given, regardless of which side of the union surfaced it.
- Covered by spec: dropped-off-roster person still enqueued, current-on-both-sides person enqueued only once, and a person whose Membership has since closed (`end_date` set) is not enqueued via the DB side.

---

## Increment 4 — Historical backfill (design finalized 2026-08-20, not yet implemented)

Goal: ingest *all* federal politicians within the 50-year window (ADR 0004), not just current ones.

**Rejected approach:** sampling roster snapshots at each election date (`getRepresentatives`/`getSenators` with a `date` param). Two problems: the project owner considers this API path unreliable in practice, and even in principle it has a coverage gap — a by-election winner who both entered and left between two general elections would never appear in any snapshot.

**Chosen approach: brute-force sweep of `person_id`.** `OpenAustralia::IngestPerson` already fetches a person's *entire* Term history regardless of how the `person_id` was discovered, and already no-ops (`nil`) when an id has no terms. So instead of discovering ids by date, sweep every `person_id` from 1 up to the highest id currently seen on the live roster, and let the existing ingest/interpret pipeline do the rest unchanged.

This design went through a `grill-me` pass after the first draft; several of the sub-steps below reflect real bugs/gaps that pass surfaced (noted inline), not just the original sketch.

### Sub-steps

1. **Enforce ADR 0004's 50-year window inside `OpenAustralia::IngestPerson`.** Nothing in the codebase enforces this today — Increment 1 achieved it only as a side effect of ingesting exclusively the current roster. Brute-forcing from id 1 will otherwise sweep in politicians back to Federation (1901) — exactly the Frederick Holder edge case ADR 0004 exists to dodge. Add a `WINDOW_YEARS = 50` guard: `call` returns `nil` (same as the existing empty-terms case) unless at least one Term's `entered_house`/`left_house` falls within the last 50 years. This is a no-op for every existing caller (current-roster ingest, monthly refresh) — it only changes behavior for genuinely-historical people this backfill discovers. Add a spec case to `spec/services/open_australia/ingest_person_spec.rb`.

   **Date parsing: reuse, and extract, don't duplicate.** `OpenAustralia::Interpretation::RawTermDates#parse_date` already handles this exact problem (treats the `"9999-12-31"` sentinel as "still ongoing" → `nil`, handles blank/malformed dates) — don't re-derive sentinel-date logic in `IngestPerson`. But it's currently namespaced under `Interpretation`, and constraint #5 (`CONTEXT.md`) keeps Ingest free of interpretation judgment calls. Resolution: **extract the module up a level**, `OpenAustralia::Interpretation::RawTermDates` → `OpenAustralia::RawTermDates` (move `app/services/open_australia/interpretation/raw_term_dates.rb` → `app/services/open_australia/raw_term_dates.rb`), since date parsing is a shared utility, not an interpretation judgment call. Update the two existing includers (`OpenAustralia::Interpretation::ExtractPeriods`, `OpenAustralia::Interpretation::ResolvePartyAffiliations`) to the new namespace; `IngestPerson` includes it too, for the window guard only.

2. **Determine the id ceiling from the live roster.** New small service `OpenAustralia::MaxKnownPersonId`, reusing the same `get_representatives`/`get_senators` calls `OpenAustralia::IngestCurrentPoliticians#roster_person_ids` already makes, returning `.map(&:to_i).max`. Current known ids run up to ~10,350 (Barnaby Joyce) — no need for precision on the floor (1), since out-of-range/no-data ids already no-op safely.

3. **429 handling in `OpenAustralia::ApiClient`.** The client currently has no rate-limit handling at all (contrast `AusTender::ScrapeSingleContractAmendment`, which explicitly checks `response.status == 429`). This backfill makes ~20-30k requests (2 per id) against an API with an unknown rate limit — worth being able to tell a 429 apart from a genuine failure. Add a distinct `OpenAustraliaRateLimitError < OpenAustraliaApiError` raised on a 429 response, so it's visible in logs/`ApiLog` as its own thing. **No custom backoff** — Sidekiq's default exponential retry is enough given app-wide Sidekiq concurrency is capped at 5, so even a retry storm can't fan out into a real burst. Revisit only if the first staging run shows 429s piling up.

4. **Backfill driver: `MaintenanceTasks::Task`, not a rake task.** Post-deploy backfills in this codebase always go through the `maintenance_tasks` gem (pause/resume/run-history for free), never `lib/tasks/*.rake` — confirmed convention, see `Maintenance::DedupeLobbyistPeopleTask` and `Maintenance::BackfillVicCouncilElectionResultsTask`.

   Two bugs found in the first draft (modeled too literally on `BackfillVicCouncilElectionResultsTask`'s index-based delay) and their fixes:
   - **`collection` must return an `Array` or `ActiveRecord::Relation`, not a bare `Range`.** `maintenance_tasks` is built on the `job-iteration` gem, whose enumerator builder rejects anything else. Fix: `.to_a`.
   - **Per-item delay must not accumulate off an absolute index.** `job-iteration` calls `@task.collection` fresh on every batch of a run, including after a pause/resume — a `delay = index * SPACING` formula computed relative to run start breaks the moment a run is paused and resumed later (wildly over- or under-delays whatever resumes). Fix: a **flat** `perform_in(SPACING, person_id)` per item — spreads out a burst without assuming an uninterrupted run.
   - **`max_person_id` must not be computed live inside `collection`.** Each job-iteration batch instantiates a new `Task`, so an instance-level `@max_person_id ||=` memo doesn't survive between batches — `collection` would hit the live roster API on every batch, and worse, a mid-run roster change would change `collection`'s size between batches, which can break cursor-based resumption (it assumes a stable, reproducible sequence). Fix, per the project owner (accepting the staleness risk, and explicitly not wanting a manual console step before starting a run): memoize at the **class** level instead of the instance level. It's computed once per Sidekiq process lifetime; a redeploy mid-run just picks up a fresh number, which is fine.

   ```ruby
   module Maintenance
     class BackfillHistoricalPoliticiansTask < MaintenanceTasks::Task
       SPACING = 2.seconds

       def collection
         (1..self.class.max_person_id).to_a
       end
       delegate :count, to: :collection

       def process(person_id)
         OpenAustralia::IngestPersonJob.perform_in(SPACING, person_id)
       end

       def self.max_person_id
         @max_person_id ||= OpenAustralia::MaxKnownPersonId.call
       end
     end
   end
   ```

   Enqueuing (not processing inline) mirrors `BackfillVicCouncilElectionResultsTask`'s reasoning: a single id's failure retries and dead-letters via Sidekiq's own machinery rather than halting the task run. Run from `/maintenance_tasks`.

5. **Add `sidekiq_options(lock: :until_executed, on_conflict: :log)` to `OpenAustralia::IngestPersonJob`.** It currently has none, which is a pre-existing gap against the hard convention that any write/idempotency-sensitive job needs this lock (`sidekiq-unique-jobs` is already a dependency). Worth closing as part of this work rather than as drive-by cleanup: this backfill runs this job at far higher volume than before, and can plausibly overlap the existing monthly `IngestCurrentPoliticiansJob` re-ingesting the same ids concurrently.

6. **Specs:**
   - `ingest_person_spec.rb` — window-filtering case (above).
   - `raw_term_dates_spec.rb` — none exists today (currently only covered indirectly via `extract_periods_spec.rb`/`resolve_party_affiliations_spec.rb`); no new requirement here, just noting the move doesn't orphan test coverage.
   - `max_known_person_id_spec.rb` — returns the max id across both chambers' rosters.
   - `api_client_spec.rb` — 429 response raises `OpenAustraliaRateLimitError`.
   - `backfill_historical_politicians_task_spec.rb` — `collection` size/type; `process` enqueues `IngestPersonJob` via `perform_in` with the flat `SPACING` delay (stub the job's `perform_in`, don't let it actually enqueue — see repo convention on stubbing job enqueues in specs). The class-level `max_person_id` memo needs explicit resetting between examples that stub it differently — implementation detail, not spelled out further here.

7. **Update this doc** once shipped: flip this section's status, and keep the rejected election-date-sampling approach summarized above as a permanent record (this file is never deleted per the `docs/plans/` taxonomy).

### Still open

- Volume: ~10-15k ids is much larger than Increment 1's one-off ~226-person run, which deliberately skipped throttling. `SPACING` above is a starting guess, not a measured value — worth watching `/maintenance_tasks` run progress and `ApiLog` error volume on the first real run (staging first) and adjusting.

---

## Later — Ministries and Cabinet offices

Each Term OpenAustralia returns already includes an `office` array — ministerial/shadow ministerial positions with date ranges (`{ moffice_id, dept, position, from_date, to_date, person, source }`). **This data is already being captured** — Increment 1 stores the whole raw Term unmodified in `open_australia_data`, `office` included. No new Ingest work is needed for this; it's purely a future Interpretation concern reading data that's already there.

When picked up:
- Each `office` entry → a `Membership` between the Person and a Department Group (find-or-create by `dept`), with a `Position` (`title` = `position` string, dates from `from_date`/`to_date`).
- A **Ministry** (the collective cabinet under a PM — "Albanese Ministry", "Morrison Ministry") is its own concept, not directly given by OpenAustralia — grouping office-holders into a Ministry needs PM tenure date ranges from elsewhere (not in this API). Design separately; don't conflate with the per-office Membership work above.

---

## Reference: OpenAustralia API

- Base URL: `https://www.openaustralia.org.au/api/`
- Auth: `key=VALUE` query param on every request — `Rails.application.credentials.dig(:open_australia, :api_key)` (now set).
- Output: `output=js` returns JSON.
- Docs: https://www.openaustralia.org.au/api/

### `getRepresentatives` / `getSenators` (roster, no ID)
Returns all members as of a given date (`date` param, ISO — omit for today). Also takes optional `party`/`search` filters, and `state` (senators only). Confirmed live: 150 representatives, 76 senators currently.

### `getRepresentative` / `getSenator` (singular, by `person_id`)
Returns that person's **full Term history** in that chamber — every row they've ever had, not just current. Confirmed field shape from live data:

```json
{
  "member_id": "6", "house": "1", "first_name": "Anthony", "last_name": "Albanese",
  "constituency": "Grayndler", "party": "Australian Labor Party",
  "entered_house": "1996-03-02", "left_house": "9999-12-31",
  "entered_reason": "general_election", "left_reason": "still_in_office",
  "person_id": "10007", "title": "", "lastupdate": "2008-04-26 11:08:04",
  "full_name": "Anthony Albanese", "name": "Anthony Albanese",
  "image": "/images/mpsL/10007.jpg",
  "office": [{ "moffice_id": "287830", "dept": "", "position": "Prime Minister",
                "from_date": "2022-06-01", "to_date": "9999-12-31", "person": "10007", "source": "" }]
}
```

Note: `house` is the string `"1"` (Representatives) or `"2"` (Senate) — **not** `"representatives"`/`"senate"` as originally guessed before live API access was available. `left_house` is `"9999-12-31"` (not blank) when currently serving.

`person_id` is stable across a person's entire career, even across chambers (confirmed: Barnaby Joyce is `person_id: "10350"` for both his Senate and House terms) — this is why `IngestPerson` calls both `get_representative` and `get_senator` for every person regardless of which chamber they're currently in.
