#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Abort if there are uncommitted changes in the current Git repository
if [[ -n $(git status --porcelain) ]]; then
    echo "Uncommitted changes detected. Please commit or stash your changes before running this script."
    exit 1
fi

# Load shared database configuration
source "$SCRIPT_DIR/db_config.sh"

# Find the most recent local dump file (pipefail disabled for the ls|head pipeline)
LATEST_DUMP=""
set +o pipefail
LATEST_DUMP=$(ls -t "$LOCAL_BACKUP_DIR"/*.sql 2>/dev/null | head -n1 || true)
set -o pipefail

# Always prompt — offer choice between fresh download and existing dump (if one exists)
if [[ -n "$LATEST_DUMP" ]]; then
    DUMP_DATE=$(stat -f "%Sm" -t "%d/%m/%Y at %H:%M" "$LATEST_DUMP")
    echo ""
    echo "Do you want to download the latest prod database, or use the dump file from $DUMP_DATE?"
    echo "  1) Download the latest production database"
    echo "  2) Use the dump file from $DUMP_DATE"
    echo ""
    read -rp "Enter 1 or 2: " CHOICE

    case "$CHOICE" in
        1)
            echo "Fetching latest backup from remote server..."
            "$SCRIPT_DIR/fetch_remote_db_backup.sh"
            set +o pipefail
            DUMP_TO_USE=$(ls -t "$LOCAL_BACKUP_DIR"/*.sql | head -n1)
            set -o pipefail
            ;;
        2)
            echo "Using existing dump from $DUMP_DATE..."
            DUMP_TO_USE="$LATEST_DUMP"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    echo "No local dump file found. Fetching latest backup from remote server..."
    "$SCRIPT_DIR/fetch_remote_db_backup.sh"
    set +o pipefail
    DUMP_TO_USE=$(ls -t "$LOCAL_BACKUP_DIR"/*.sql | head -n1)
    set -o pipefail
fi

# Drop and recreate the local database
echo "Dropping and recreating local database..."
rails db:drop && rails db:create

# Restore the backup data to the newly created local database
echo "Restoring backup data to local database..."
psql -d "$LOCAL_DB" < "$DUMP_TO_USE"

# Migrate the database
echo "Running migrations..."
rails db:migrate

echo "Database backup and restore process completed successfully!"

# Silently remove any dump files older than the one we just used
for dump in "$LOCAL_BACKUP_DIR"/*.sql; do
    if [[ "$dump" != "$DUMP_TO_USE" ]]; then
        rm -f "$dump"
    fi
done
