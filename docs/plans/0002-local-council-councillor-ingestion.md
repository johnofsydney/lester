# Local Council Councillor Ingestion (NSW + VIC Electoral Commissions)

**Status:** Proposed

## Context

Join the Dots currently maps federal/state political affiliations, donations, and government contracts, but has no coverage of local government. The original framing was "scrape every council's own website" (elected members and staff), inferring departures from who drops off the page — but that runs into two hard problems: there's no master list of ~530 councils to start from, and a scraped "current roster" page never tells you *when* someone left, only that they're gone now.

Research during planning found that NSW and VIC electoral commissions solve both problems for the elected-member half: both publish clean, consistent, plain-HTML, per-council declared-election results (NSW: `pastvtr.elections.nsw.gov.au/LG<year>/<council-slug>/councillor`; VIC: `vec.vic.gov.au/results/council-election-results/<year>-council-election-results/<council-slug>`), each with a browsable index of every council in the state. That means: no separate "find the list of councils" step (the index page *is* the list), no separate "master list of councils" step (the state's own index page is authoritative for that state), and real, authoritative `start_date`/`end_date` for memberships instead of a "last seen" heuristic. The other 5 states/territories have messier sources (JS single-page apps, per-council PDFs, or unconfirmed) — explicitly **out of scope for this phase**.

Given that, you decided to **narrow this phase to NSW + VIC electoral commission ingestion only** — no council-website scraping at all yet (which also means no executive-staff coverage yet; that's a distinct future phase once we're back to scraping council sites directly). This removes most of the complexity from earlier drafts of this plan:

- **No new `Council` model/table.** A council is just a `Group`, exactly like every other organisation in the graph. Councillors are `Person` records. Membership (with real start/end dates) links them, exactly like everywhere else in the app.
- **No admin dashboard.** You compared this to how AEC/ACNC/AusTender ingestion already works — a trusted, structured, low-frequency data source doesn't need a bespoke monitoring UI, just the existing `ApiLog` error-logging convention those jobs already use. Existing `Admin::Groups`/`Admin::People`/`Admin::Memberships` screens (filtered by the new tag) give all the visibility needed.
- **No new scraper-config table.** Since each state scraper discovers its own council list by crawling that state's index page fresh each run, there's nothing per-council to configure or store ahead of time.

One piece of existing code carries forward: `Group::RecordRow` (`app/services/group/record_row.rb`), which creates a Membership + Position for a person in a group. It currently has exactly one caller — `app/admin/leadership_websites.rb:84` — confirmed by grep, so it's safe to change its interface. You confirmed: keep and fix it (it accepts `evidence:`/`start_date:`/`end_date:` today but silently never applies them — a real bug), and change it to accept an already-resolved `person:` object rather than resolving a `person_name:` string itself, since the caller (an electoral-commission scraper) needs its own name-cleanup logic anyway. Everything else from the earlier "LeadershipWebsite" effort — the model, its ActiveAdmin screen, and the `Discovery::Website::PageDownloader`/`PageParser` services built for it — gets **removed**, not extended. You called it a reasonable idea that wasn't executed well; it may come back later as a fresh build once we return to council-website scraping, but not as part of this work.

## Data model

**No new tables.** Reuses the existing Group/Person/Membership graph:

- **Councils are `Group` records**, found/created via the existing `Groups::RecordGroup.call(name)` (same disambiguation-by-name path every other organisation uses — if a council already exists as a Group from AusTender contract data under the same name, this naturally reuses it rather than creating a duplicate).
- **A new Tag**, `"Australian Local Councils"`, created once via `Group.find_or_create_by!(name: 'Australian Local Councils', type: 'Tag')`, exposed as a new `Group.local_councils_tag` method alongside the existing `charities_tag`/`lobbyists_tag`/`client_of_lobbyists_tag`/`government_department_tag` (`app/models/group.rb:216-230`). Unlike those, it does **not** get a hardcoded ID yet — this tag doesn't exist in production until this work ships, and the hardcoded-ID convention only applies once a record actually exists there (IDs get hardcoded after pulling down the real production ID). So for now: `def self.local_councils_tag; Group.find_by(name: 'australian local councils'); end` (name-based lookup, matching the existing `Group#normalizes :name` downcasing). Once this ships and we have the real production ID, swap it to a hardcoded `Group.find(id)` like the others, as a small follow-up change. Every council Group gets added to it via the existing `Group#add_to_tag`/`Tag::AddGroupToTag` (`app/models/group.rb:198-204`, `app/services/tag/add_group_to_tag.rb`) — the same mechanism already used for categories like "Mining".
- **Councillors are `Person` records**, found/created via the existing `People::RecordPerson.call(name)`.
- **Membership** (existing table, existing columns — `start_date`, `end_date`, `evidence`, no schema changes needed) links councillor to council, with **real dates from the declared election result**, not inferred ones.
- **Party affiliation** (NSW only — VIC's results page doesn't show it): where the ballot shows a party/group label, link the councillor Person to the existing party Tag Group (e.g. `NAMES.labor.nsw` → `'alp (nsw)'`, from `Group::NAMES` in `app/models/group.rb:47-57`) via another Membership, using a small label-mapping table in the NSW scraper (ballot labels like "Australian Labor Party" don't exactly match the stored Tag names). Independents are skipped — no party Membership created.

**`Group::RecordRow` changes** (`app/services/group/record_row.rb`):
- `person:` (required, a `Person` AR object) replaces `person_name:` — callers resolve the Person themselves first (via `People::RecordPerson.call`)
- Actually apply `evidence:`/`start_date:`/`end_date:` to the created/updated `Membership` when present, instead of silently ignoring them (today's bug)
- Its only current caller (`app/admin/leadership_websites.rb`) is being deleted as part of this work (see below), so this is a clean interface change with no other call sites to update

## Removing the LeadershipWebsite effort

As agreed, delete rather than repurpose:
- `app/models/leadership_website.rb`
- `app/admin/leadership_websites.rb` (+ its preview view, `app/views/admin/leadership_websites/preview.html*` if present)
- `app/services/discovery/website/page_downloader.rb`, `app/services/discovery/website/page_parser.rb`
- The `has_many :leadership_websites` association on `Group` (`app/models/group.rb:72`)
- A migration to drop the `leadership_websites` table

## Ingestion design

Follows the existing per-source Sidekiq convention (`AuLobbyists::`, `AusTender::`, `Acnc::`) — two independent namespaces, `Councils::Nsw::` and `Councils::Vic::`, each with the same two-job shape already used by `AuLobbyists` (top-level "ingest" job that discovers work, fans out to per-item "import" jobs):

- **`Councils::Nsw::IngestElectionResultsJob`** — fetches the NSW Electoral Commission's council results index, discovers every council + its per-council results URL, enqueues `Councils::Nsw::ImportCouncilResultRowJob` per council with staggered `perform_in(rand(...).seconds, ...)` jitter (same pattern as `TenderIngestor`/`AusTender::BackfillContractsMasterJob`), so we don't hit the Commission's site with ~130 simultaneous requests.
- **`Councils::Nsw::ImportCouncilResultRowJob`** — **not a single-page fetch, as originally planned.** Live testing found NSW councils split into two structurally different shapes: "at-large" councils have one flat `<slug>/councillor` results page, but ward-divided councils (e.g. Blacktown, Hornsby) have *no flat page at all* — the only way to find their per-ward contests is to fetch `<slug>/results` first. So the job always fetches `<slug>/results` first, parses it with `Councils::Nsw::ResultsPageParser` to discover one or more councillor-contest paths (`["councillor"]` for at-large, `["ward-1/councillor", "ward-2/councillor", ...]` for ward-divided — explicitly excluding any separately-elected Mayor contest, out of scope), then fetches and parses each contest page. Candidates from every contest are recorded as `Person`s (via `People::RecordPerson`) with a `Councillor` `Membership`/`Position` on the council `Group` (via `Groups::RecordGroup`, tagging it into `local_councils_tag` if newly created), `start_date:` = that contest's declared date, `evidence:` citing the NSW Electoral Commission + election year. Departed members are only closed out (`end_date:` = the *latest* declared date across all contests, since wards can declare on different dates) once **every** discovered contest has actually declared — if one ward hasn't declared yet, its sitting councillors are simply absent from this run's results, and closing them out early would wrongly read as "not returned."
- **`Councils::Vic::IngestElectionResultsJob`** / **`Councils::Vic::ImportCouncilResultRowJob`** — mirrors the NSW pair, minus party-affiliation capture (not on the VIC page). Unlike NSW, a single fetch of `<slug>` already contains every ward inline — no separate discovery step needed. The parser (`Councils::Vic::CouncillorResultsParser`) does need to walk *every* "Elected candidates" section on the page, not just the first: ward-divided councils have one section per ward, and a handful of councils (e.g. Melbourne) have an additional, separately-elected "Leadership Team" (Lord Mayor/Deputy Lord Mayor) contest alongside "Councillors" — the parser identifies each section's contest by its nearest preceding heading and excludes any titled "Leadership Team". **Known accepted gap:** VIC has no equivalent of NSW's "wait for every contest to declare" guard — `close_departed_members` runs as soon as the page has any declared section. This was left unbuilt because the 2024 election (the only one this ingests so far) is long since fully declared, so every real page fetched is 100% complete; there was no verified real example of a *partially* declared multi-ward VIC page to build and test the guard against. Worth revisiting before the 2028 election if this ever runs during a live, in-progress count.

Both follow the existing error-handling convention exactly as seen in `app/sidekiq/aus_tender/ingest_contracts_date_job.rb:14-23` — `rescue`, log via `ApiLog.create(endpoint:, message:)`, `raise e` so Sidekiq's native retry applies. No new run-log model.

**Explicitly out of scope for this phase:** council-website scraping (so no executive staff yet), mid-term countback/by-election tracking (both states publish these separately from general-election results; revisit once the general-election path is proven), and historical backfill (only the current/most recent declared term is ingested — building out full past-tenure history is a later enrichment once we trust this pipeline).

## Scheduling

Both NSW and VIC last held general elections in 2024; the next are 2028. There's no live cadence problem to solve *right now* — the jobs are run manually (console or Sidekiq Web) for the initial current-term backfill. Because everything here is idempotent (`Groups::RecordGroup`/`People::RecordPerson`/`Membership.find_or_create_by`-style lookups), re-running is always safe. A `sidekiq-scheduler` cron entry (e.g. monthly, active only in each state's election year) can be added to `config/sidekiq.yml` closer to 2028 rather than building scheduling logic now for an event years away.

## Verification

- `bundle exec rspec` — new specs for the fixed `Group::RecordRow` (person: object, evidence/date application), and for the NSW/VIC scrapers (real parsing logic exercised, HTTP layer stubbed, per your existing convention)
- Run `Councils::Nsw::IngestElectionResultsJob.new.perform` manually in `bin/rails console` restricted to a small number of real councils first (spot-check before the full ~130-council fan-out), inspect the resulting `Group`/`Person`/`Membership` records and party-tag links
- Same for VIC
- Confirm removing `LeadershipWebsite` doesn't break other specs (`grep -r LeadershipWebsite spec/` first, then run the suite)
- Browse `/admin/groups` filtered to the "Australian Local Councils" tag, and `/admin/memberships` for a pilot council, to confirm the data reads sensibly through existing admin screens with no new UI
