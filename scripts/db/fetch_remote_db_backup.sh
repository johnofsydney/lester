#!/bin/bash
set -euo pipefail

REMOTE_USER=$LESTER_REMOTE_USER # "your_remote_user"
REMOTE_HOST=$LESTER_REMOTE_DB_HOST # "your_remote_host"

REMOTE_DB=$LESTER_REMOTE_DB # "your_database_name"
REMOTE_DB_USER=$LESTER_REMOTE_DB_USER # "your_database_user"
# REMOTE_DB_HOST=$LESTER_REMOTE_DB_HOST # "your_database_host"
LESTER_REMOTE_DB_PASSWORD=$LESTER_REMOTE_DB_PASSWORD # "your_database_password"

LOCAL_BACKUP_DIR=$LESTER_LOCAL_BACKUP_DIR  # Use $HOME instead of ~ ## FOR LOCAL ##
REMOTE_BACKUP_DIR=$LESTER_REMOTE_BACKUP_DIR  # Use $HOME instead of ~
BACKUP_FILE=$LESTER_BACKUP_FILE
LOCAL_DB=$LESTER_LOCAL_DB
LOCAL_DB_USER=$LESTER_LOCAL_DB_USER

required_vars=(
  LESTER_REMOTE_USER
  LESTER_REMOTE_DB_HOST
  LESTER_REMOTE_DB
  LESTER_REMOTE_DB_USER
  LESTER_REMOTE_DB_PASSWORD
  LESTER_LOCAL_BACKUP_DIR
  LESTER_REMOTE_BACKUP_DIR
  LESTER_BACKUP_FILE
  LESTER_LOCAL_DB
  LESTER_LOCAL_DB_USER
)

missing_vars=0
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required environment variable: ${var_name}"
    missing_vars=1
  fi
done

if [[ $missing_vars -ne 0 ]]; then
  exit 1
fi

# Step 1: SSH into the remote server and create a backup of the database
ssh "$REMOTE_USER@$REMOTE_HOST" << EOF
  echo "Creating backup on remote server..."

  # Set password for this session
  export PGPASSWORD='$LESTER_REMOTE_DB_PASSWORD'

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
