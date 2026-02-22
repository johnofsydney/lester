#!/bin/bash

# Abort if there are uncommitted changes in the current Git repository
if [[ -n $(git status --porcelain) ]]; then
    echo "Uncommitted changes detected. Please commit or stash your changes before running this script."
    exit 1
fi

# Variables (update these with your own credentials and paths)

REMOTE_USER=$LESTER_REMOTE_USER # "your_remote_user"
REMOTE_HOST=$LESTER_REMOTE_DB_HOST # "your_remote_host"

REMOTE_DB=$LESTER_REMOTE_DB # "your_database_name"
REMOTE_DB_USER=$LESTER_REMOTE_DB_USER # "your_database_user"
REMOTE_DB_HOST=$LESTER_REMOTE_DB_HOST # "your_database_host"
LESTER_REMOTE_DB_PASSWORD=$LESTER_REMOTE_DB_PASSWORD # "your_database_password"

LOCAL_BACKUP_DIR=$LESTER_LOCAL_BACKUP_DIR  # Use $HOME instead of ~ ## FOR LOCAL ##
REMOTE_BACKUP_DIR=$LESTER_REMOTE_BACKUP_DIR  # Use $HOME instead of ~
BACKUP_FILE=$LESTER_BACKUP_FILE
LOCAL_DB=$LESTER_LOCAL_DB
LOCAL_DB_USER=$LESTER_LOCAL_DB_USER

echo "REMOTE_USER: $REMOTE_USER"
echo "REMOTE_HOST: $REMOTE_HOST"

echo "REMOTE_DB_HOST: $REMOTE_DB_HOST"
echo "REMOTE_DB: $REMOTE_DB"
echo "REMOTE_DB_USER: $REMOTE_DB_USER"

echo "LOCAL_BACKUP_DIR: $LOCAL_BACKUP_DIR"
echo "REMOTE_BACKUP_DIR: $REMOTE_BACKUP_DIR"
echo "BACKUP_FILE: $BACKUP_FILE"
echo "LOCAL_DB: $LOCAL_DB"
echo "LOCAL_DB_USER: $LOCAL_DB_USER"

# # Prompt the user to ask if they want to download the backup from the remote server
read -p "Do you want to download the backup from the remote server? (y/n): " download_choice

if [[ "$download_choice" == "y" || "$download_choice" == "Y" ]]; then
    echo "Fetching latest backup from remote server..."
    ./fetch_remote_db_backup.sh
    if [[ $? -ne 0 ]]; then
        echo "Error: fetch_remote_db_backup.sh failed. Aborting..."
        exit 1
    fi
else
    echo "Using existing local backup file..."
fi

# # Step 4: Drop and recreate the local database
echo "Dropping and recreating local database..."
rails db:drop && rails db:create

# # Step 5: Restore the backup data to the newly created local database
echo "Restoring backup data to local database..."
psql -d $LOCAL_DB < $LOCAL_BACKUP_DIR/$BACKUP_FILE

# # Step 6: Migrate the database
echo "Running migrations..."
rails db:migrate

echo "Database backup and restore process completed successfully!"
