# Seeding local and staging databases

Local dev and staging no longer need a full copy of production. Instead, a small curated
subset of real data — a few dozen groups, a couple hundred people, and the transfers/
memberships/positions connecting them — is extracted once from a full-data database and
committed to the repo as YAML fixtures under `db/seed_data/`.

## Re-extracting the seed data (occasional, e.g. after a data ingest you want reflected in seeds)

Run against whichever database currently holds the full dataset (staging, if it's still a
full prod copy, or production read-only):

```bash
RAILS_ENV=staging bin/rails seed_data:extract
```

This overwrites `db/seed_data/*.yml`. Review the diff, then commit.

The task deliberately runs from the giver/taker-and-membership side outward from a small
seed set (hardcoded tag/group IDs, major parties, current federal parliament, and the
highest-transfer-volume people/groups) rather than following tag groups (e.g. Charities,
Lobbyists) out to their full membership — that's what keeps the subset small. See
`lib/tasks/seed_data.rake` for the exact selection logic and limits.

## Loading seed data into a database (local dev, or a freshly created staging DB)

```bash
bin/rails db:create db:schema:load db:seed
```

`db:seed` loads `db/seed_data/*.yml`, preserving primary keys — several group IDs are
hardcoded elsewhere in the codebase (`Group.charities_tag` and friends), so the extracted
IDs must survive the round trip unchanged. It's only safe to run against an empty database;
it doesn't truncate existing data first.

For a worktree-local database, set `DEV_DATABASE_NAME` (see `config/database.yml`) before
running the above.
