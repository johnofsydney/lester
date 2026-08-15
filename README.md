# Join the Dots

An Australian political transparency tool that maps relationships between people, organisations, money flows (donations and government contracts), and political affiliations. Live at [join-the-dots.info](https://join-the-dots.info) — see [`/about`](https://join-the-dots.info/about) for the project's mission.

For architecture, domain model, and stack details, see [`CLAUDE.md`](CLAUDE.md) and [`CONTEXT.md`](CONTEXT.md).

## Setup

Requires Ruby 3.4.7 (see `.ruby-version`), Node.js ≥22.12, and PostgreSQL.

```bash
bundle install
npm install
bin/rails db:setup
```

## Running locally

```bash
bin/dev   # runs Rails + Vite together (see Procfile.dev)
```

## Tests

```bash
bundle exec rspec                             # full suite
bundle exec rspec spec/models/person_spec.rb  # single file
```

## Linting & security

```bash
bundle exec rubocop
bundle exec brakeman
bundle exec bundler-audit check --update
```

## Deployment

Deployed to [Hatchbox](https://hatchbox.io). See `notes/runbook-hung-staging-deploy.md` and `notes/database.creating.prod.dump.as.staging.md` for operational runbooks.
