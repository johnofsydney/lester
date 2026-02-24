#!/bin/bash
set -euo pipefail

PROD_DB="lester_production"
STAGING_DB="lester_staging"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="/tmp/${PROD_DB}_${TIMESTAMP}.dump"
LOG_FILE="/tmp/refresh_${TIMESTAMP}.log"

exec > >(tee -a ${LOG_FILE}) 2>&1

echo "================================================="
echo "Lester Staging Refresh Script"
echo "Time: $(date)"
echo "================================================="
echo

echo "⚠️  CONFIRMATION REQUIRED"
echo
echo "1) Have you DISABLED staging in Hatchbox?"
echo "2) Have you verified Puma + Sidekiq are stopped?"
echo
read -p "Type YES to confirm staging is disabled: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborting."
  exit 1
fi

echo
echo "Checking for active staging DB connections..."
ACTIVE_CONN=$(sudo -u postgres psql -t -c "
SELECT count(*) FROM pg_stat_activity
WHERE datname = '${STAGING_DB}';
" | xargs)

if [[ "$ACTIVE_CONN" != "0" ]]; then
  echo "❌ ${ACTIVE_CONN} active connections found."
  echo "Terminate them before proceeding."
  exit 1
fi

echo "✅ No active staging connections."
echo

echo "Production DB size:"
sudo -u postgres psql -c "
SELECT pg_size_pretty(pg_database_size('${PROD_DB}'));
"

echo "Staging DB size:"
sudo -u postgres psql -c "
SELECT pg_size_pretty(pg_database_size('${STAGING_DB}'));
"

echo
echo "🚨 FINAL WARNING 🚨"
echo "This will DROP and RECREATE '${STAGING_DB}' from '${PROD_DB}'."
echo
read -p "Type REFRESH to proceed: " FINAL_CONFIRM

if [[ "$FINAL_CONFIRM" != "REFRESH" ]]; then
  echo "Aborting."
  exit 1
fi

echo
echo "Terminating staging connections (double-check)..."
sudo -u postgres psql -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '${STAGING_DB}';
"

echo "Dumping production..."
sudo -u postgres pg_dump -Fc ${PROD_DB} -f ${DUMP_FILE}

echo "Dropping staging..."
sudo -u postgres dropdb --if-exists ${STAGING_DB}

echo "Recreating staging..."
sudo -u postgres createdb ${STAGING_DB}

echo "Restoring into staging..."
sudo -u postgres pg_restore -d ${STAGING_DB} ${DUMP_FILE}

echo "New staging DB size:"
sudo -u postgres psql -c "
SELECT pg_size_pretty(pg_database_size('${STAGING_DB}'));
"

echo "Cleaning up dump file..."
rm ${DUMP_FILE}

echo
echo "✅ SUCCESS: Staging refreshed from production."
echo "Log saved to: ${LOG_FILE}"
echo

# This file is here in the repo for version control. It is not meant to be run directly. Instead, it should be copied to the server and run from there.

# Run this from the laptop to copy the script to the server and run chmod +x on it:
# $ scp scripts/db/copy_prod_to_staging.sh "deploy@$LESTER_REMOTE_DB_HOST":/home/deploy/
# $ chmod +x copy_prod_to_staging.sh

# Then to run the script on the server:
# $ ssh deploy@{LESTER_REMOTE_DB_HOST}
# $ ./copy_prod_to_staging.sh
