#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Abort if there are uncommitted changes in the current Git repository
if [[ -n $(git status --porcelain) ]]; then
    echo "Uncommitted changes detected. Please commit or stash your changes before running this script."
    exit 1
fi

# Parse command line arguments
SKIP_FETCH=false
if [[ "${1:-}" == "--skip-fetch" ]]; then
    SKIP_FETCH=true
fi

# Load shared database configuration
source "$SCRIPT_DIR/db_config.sh"

# Fetch remote backup unless --skip-fetch flag is used
if [[ "$SKIP_FETCH" == true ]]; then
    echo "Skipping remote fetch (--skip-fetch flag provided)..."
    echo "Using existing local backup file: $LOCAL_BACKUP_DIR/$BACKUP_FILE"
else
    echo "Fetching latest backup from remote server..."
    "$SCRIPT_DIR/fetch_remote_db_backup.sh"
fi

# # Step 4: Drop and recreate the local database
echo "Dropping and recreating local database..."
rails db:drop && rails db:create

# # Step 5: Restore the backup data to the newly created local database
echo "Restoring backup data to local database..."
psql -d "$LOCAL_DB" < "$LOCAL_BACKUP_DIR/$BACKUP_FILE"

# # Step 6: Migrate the database
echo "Running migrations..."
rails db:migrate

echo "Database backup and restore process completed successfully!"
