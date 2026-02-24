#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load shared database configuration
source "$SCRIPT_DIR/db_config.sh"

# Step 1: SSH into the remote server and create a backup of the database
ssh "$REMOTE_USER@$REMOTE_HOST" <<EOF
    set -e
    mkdir -p "$REMOTE_BACKUP_DIR"
    PGPASSWORD="$LESTER_REMOTE_DB_PASSWORD" \
    pg_dump "$REMOTE_DB" -U "$REMOTE_DB_USER" -h localhost > "$REMOTE_BACKUP_DIR/$BACKUP_FILE"
EOF

# Check if SSH failed due to permission issues
if [[ $? -ne 0 ]]; then
    echo "Error: Permission denied or SSH failure. Aborting script."
    exit 1
fi

# Step 2: Copy the backup file from the remote server to the local machine
echo "Copying backup file to local machine..."
scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_BACKUP_DIR/$BACKUP_FILE" "$LOCAL_BACKUP_DIR/$BACKUP_FILE"
# scp user@host_ip:~/db_dumps/database.bak ~/Desktop/database.bak

# Step 3: Delete the backup file from the remote server
ssh "$REMOTE_USER@$REMOTE_HOST" << EOF
    echo "Deleting remote backup file..."
    rm -f "$REMOTE_BACKUP_DIR/$BACKUP_FILE"
EOF
