#!/bin/bash
# Shared database configuration for load_latest_database.sh and fetch_remote_db_backup.sh
# Source this file with: source "$(dirname "${BASH_SOURCE[0]}")/db_config.sh"

set -euo pipefail

# Remote server variables
REMOTE_USER=$LESTER_REMOTE_USER
REMOTE_HOST=$LESTER_REMOTE_DB_HOST
REMOTE_DB=$LESTER_REMOTE_DB
REMOTE_DB_USER=$LESTER_REMOTE_DB_USER
REMOTE_DB_HOST=$LESTER_REMOTE_DB_HOST
LESTER_REMOTE_DB_PASSWORD=$LESTER_REMOTE_DB_PASSWORD

# Local variables
LOCAL_BACKUP_DIR=$LESTER_LOCAL_BACKUP_DIR
REMOTE_BACKUP_DIR=$LESTER_REMOTE_BACKUP_DIR
BACKUP_FILE=$LESTER_BACKUP_FILE
LOCAL_DB=$LESTER_LOCAL_DB
LOCAL_DB_USER=$LESTER_LOCAL_DB_USER

# Validate required environment variables
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
  echo "Error: Please set all required LESTER_* environment variables"
  exit 1
fi

echo "REMOTE_USER: $REMOTE_USER"
echo "REMOTE_HOST: $REMOTE_HOST"
echo "REMOTE_DB: $REMOTE_DB"
echo "REMOTE_DB_USER: $REMOTE_DB_USER"
echo "LOCAL_BACKUP_DIR: $LOCAL_BACKUP_DIR"
echo "REMOTE_BACKUP_DIR: $REMOTE_BACKUP_DIR"
echo "BACKUP_FILE: $BACKUP_FILE"
echo "LOCAL_DB: $LOCAL_DB"
echo "LOCAL_DB_USER: $LOCAL_DB_USER"