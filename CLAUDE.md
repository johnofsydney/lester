# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

"Join the Dots" — an Australian political transparency tool that maps relationships between people, organisations, money flows (donations and government contracts), and political affiliations. The live site is join-the-dots.info.

## Stack

- Ruby 3.4.7, Rails 8.1, PostgreSQL
- Vite 8 + React 18 (via `inertia_rails` for the network graph page only)
- Bootstrap 5 (loaded via CDN in layout, JS via npm)
- ActiveAdmin for the back-office
- Sidekiq + sidekiq-scheduler for background jobs
- Phlex for some view components
- Flipper for feature flags
- New Relic for error tracking in production
- Deployed to Hatchbox

## Commands

```bash
# Dev server (runs Rails + Vite together)
bin/dev          # uses Procfile.dev: rails s + bin/vite dev

# Tests
bundle exec rspec                          # full suite
bundle exec rspec spec/models/person_spec.rb  # single file
bundle exec rspec spec/models/person_spec.rb:42  # single example

# Linting
bundle exec rubocop
bundle exec rubocop -a   # auto-correct

# Security
bundle exec brakeman
bundle exec bundler-audit check --update

# Frontend build
npm run build:production   # NODE_ENV=production vite build
```

Node.js ≥22.12 is required (Vite 8 / rolldown constraint).

## Architecture

### Core domain model

The graph has two entity types — **Person** and **Group** — connected by:

- **Membership** (polymorphic `member`: Person or Group → belongs to a Group). A person or sub-group can have multiple memberships in the same group over time (e.g. rejoining).
- **Transfer** (polymorphic `giver`/`taker`: Person or Group → Person or Group). `transfer_type` is either `donations` or `government_contracts`.
- **Tag** is a subclass of Group (`type: 'Tag'`). Tags are used as political party labels and category labels (Charities, Lobbyists, etc.). Several tags have hardcoded IDs relied on in scopes (e.g. `Group.charities_tag` → id 124513).

Both Person and Group include three concerns: `NodeMethods` (live graph traversal & money aggregation), `CachedMethods` (cache access via `cached_data` jsonb column), and `TransferMethods`. They also include `ExternalIdentifiable`, which gives access to the `external_identifiers` polymorphic table (sources: `aec`, `acnc`, `open_australia`).

Names on both Person and Group are normalised on save: downcased, stripped, `.` removed.

### Graph traversal & caching

`Descendent` is a **non-AR value object** (no table) representing a node at a given depth in the relationship graph. It carries display metadata (shape, color, mass, size, depth-coded by colour) for the vis-network frontend.

`BuildQueue` is the graph traversal engine — it expands one level at a time from a starting node, filtering via `CanAddToQueue`. Groups with >50 members (`MAX_GROUP_SIZE_TO_FOLLOW`) are not followed to avoid blowing up traversal.

`CachedMethods#cached` returns a `RehydratedNode` which deserialises the `cached_data` jsonb column. Cache freshness is 1 week. If stale, the controller enqueues `BuildPersonCachedDataJob` / `BuildGroupCachedDataJob` and renders a "please refresh" page.

### Inertia / React

Only the network graph page uses React. `InertiaController` renders `inertia: 'NetworkGraph'` with pre-serialised JSON props. The React component lives at `app/javascript/pages/NetworkGraph.jsx`. The Inertia entrypoint is `app/javascript/entrypoints/inertia.js`.

All other pages use standard Rails ERB views, with Phlex components for some shared UI elements.

### Data ingestion

Background jobs (Sidekiq) ingest from:
- **AEC** — political donation disclosures (`app/sidekiq/au_aec_donations/`)
- **ACNC** — charity registry (`app/sidekiq/acnc_charities/`)
- **AusTender** — government contracts (`app/sidekiq/aus_tender/`, `app/sidekiq/backfill_contracts_master_job.rb`)
- **ABN Lookup** — business name resolution
- **Lobbyist register** (`app/sidekiq/au_lobbyists/`)
- **OpenAustralia** — federal politician parliamentary/party history (`app/services/open_australia/`, `app/sidekiq/open_australia/`). Split into Ingest (fetch and store raw Terms, no interpretation) and Interpretation (derive Membership/Position records from stored Terms) — see `CONTEXT.md`'s "OpenAustralia ingest" section and `docs/adr/0001`–`0005` for the vocabulary and decisions this split relies on.

Services under `app/services/` follow the pattern: a top-level `RecordPerson`, `RecordGroup`, or `RecordTransfer` service that upserts the entity, with sub-services for source-specific logic. `ExternalIdentifier` records are used to disambiguate entities across sources.

### Person disambiguation

See `docs/plans/0006-person-disambiguation-design.md` (now a historical design record — implemented). `external_identifiers` (polymorphic, source-keyed) is the primary merge key when a source ID is present; `trading_names` captures name variants; name-only matching is the fallback when no ID is available. See `People::RecordPerson`, `Entity::RecordEntityWithExternalId`, and `ExternalIdentifiable`.

### Admin

ActiveAdmin at `/admin` (authenticated via Devise `AdminUser`). Key custom actions: `Admin::People#ingest_linkedin`, `Admin::People::ExplodePerson` (splits a falsely-merged person), `Admin::Groups#perform_merge`, membership bulk upload.

Flipper UI at `/flipper`, Sidekiq Web at `/sidekiq` — both behind `authenticate :admin_user`.

## Agent skills

### Future work / issue tracking

The primary mechanism is repo-file backlog notes: `docs/backlog/` holds one file per
not-yet-committed idea (see `CODING_STANDARDS.md`'s `## Docs` section for the full taxonomy).
GitHub issues in johnofsydney/lester, managed via the `gh` CLI, are a secondary channel used
occasionally (e.g. away from the primary laptop) — see `docs/agents/issue-tracker.md` for how to
work with them. A `docs/backlog/` idea is promoted to a numbered `docs/plans/` entry or a GitHub
issue once committed to; the original backlog file is then deleted.

### Domain docs

Single-context layout — `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
