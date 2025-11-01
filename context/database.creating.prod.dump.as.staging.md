# Lester Staging Setup Cheat Sheet

## Step 1 — Local DB rename (optional)

```bash
sudo -i -u postgres
psql postgres
ALTER DATABASE sunshine_guardian_development RENAME TO lester_development;
ALTER DATABASE sunshine_guardian_test RENAME TO lester_test;
\q
```

Update `config/database.yml`:

```yaml
development:
  <<: *default
  database: lester_development

test:
  <<: *default
  database: lester_test
```

Verify:

```bash
bin/rails db:migrate:status
bin/rails test
```

## Step 2 — Rails staging environment

```bash
cp config/environments/production.rb config/environments/staging.rb
```

Edit `staging.rb` for staging-specific tweaks.
Update `config/database.yml`:

```yaml
staging:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
```

Set Hatchbox environment variable:

```
RAILS_ENV=staging
```

## Step 3 — Setup staging database

### 3.1 Detach old DB in Hatchbox (if any)

### 3.2 Create new DB

```sql
CREATE DATABASE lester_staging WITH OWNER postgres ENCODING 'UTF8' TEMPLATE template0;
CREATE USER lester_staging_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE lester_staging TO lester_staging_user;
```

### 3.3 Copy production data

```bash
sudo -i -u postgres
pg_dump -Fc lester_production -f /tmp/lester_prod.dump
pg_restore -d lester_staging /tmp/lester_prod.dump --no-owner --role=postgres
```

Verify:

```bash
psql -d lester_staging
\dt
SELECT * FROM people LIMIT 5;
```

### 3.4 Attach staging DB in Hatchbox

* Attach `lester_staging` to staging app
* Hatchbox will set `DATABASE_URL`

## Step 4 — Verify staging

* Make a test change → ensure production is unaffected
* Check migrations:

```bash
RAILS_ENV=staging bin/rails db:migrate:status
```

* Deploy staging app via Hatchbox

## Notes / Tips

* Sidekiq works without `config.active_job.queue_adapter` if using direct workers.
* Optional staging credentials:

```bash
bin/rails credentials:edit --environment staging
```

* Cleanup dump file:

```bash
rm /tmp/lester_prod.dump
```
