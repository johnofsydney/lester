#!/bin/bash
# Shared database configuration for load_latest_database.sh and fetch_remote_db_backup.sh
# Source this file with: source "$(dirname "${BASH_SOURCE[0]}")/db_config.sh"

set -euo pipefail

# Hardcoded — not sensitive, same across machines
REMOTE_USER=deploy
REMOTE_BACKUP_DIR=db_dumps
BACKUP_FILE=latest_backup.sql
LOCAL_DB=lester_development
LOCAL_BACKUP_DIR=/Users/john/db_backups

# Environment variables — set these in your shell profile (~/.zshrc or ~/.bashrc):
#   export LESTER_REMOTE_DB_HOST=...
#   export LESTER_REMOTE_DB=...
#   export LESTER_REMOTE_DB_USER=...
#   export LESTER_REMOTE_DB_PASSWORD=...
required_vars=(
  LESTER_REMOTE_DB_HOST
  LESTER_REMOTE_DB
  LESTER_REMOTE_DB_USER
  LESTER_REMOTE_DB_PASSWORD
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Error: ${var_name} environment variable is not set."
    exit 1
  fi
done

REMOTE_HOST=$LESTER_REMOTE_DB_HOST
REMOTE_DB=$LESTER_REMOTE_DB
REMOTE_DB_USER=$LESTER_REMOTE_DB_USER
