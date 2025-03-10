#!/bin/bash



# Abort if there are uncommitted changes in the current Git repository
if [[ -n $(git status --porcelain) ]]; then
    echo "Uncommitted changes detected. Please commit or stash your changes before running this script."
    exit 1
fi

# Variables (update these with your own credentials and paths)

REMOTE_USER=$LESTER_REMOTE_USER # "your_remote_user"
REMOTE_HOST=$LESTER_REMOTE_HOST # "your_remote_host"
REMOTE_DB=$LESTER_REMOTE_DB # "your_database_name"
REMOTE_DB_USER=$LESTER_REMOTE_DB_USER # "your_database_user"
LOCAL_BACKUP_DIR=$LESTER_LOCAL_BACKUP_DIR  # Use $HOME instead of ~ ## FOR LOCAL ##
REMOTE_BACKUP_DIR=$LESTER_REMOTE_BACKUP_DIR  # Use $HOME instead of ~
BACKUP_FILE=$LESTER_BACKUP_FILE
LOCAL_DB=$LESTER_LOCAL_DB
LOCAL_DB_USER=$LESTER_LOCAL_DB_USER

echo "REMOTE_USER: $REMOTE_USER"
echo "REMOTE_HOST: $REMOTE_HOST"
echo "REMOTE_DB: $REMOTE_DB"
echo "REMOTE_DB_USER: $REMOTE_DB_USER"
echo "LOCAL_BACKUP_DIR: $LOCAL_BACKUP_DIR"
echo "REMOTE_BACKUP_DIR: $REMOTE_BACKUP_DIR"
echo "BACKUP_FILE: $BACKUP_FILE"
echo "LOCAL_DB: $LOCAL_DB"
echo "LOCAL_DB_USER: $LOCAL_DB_USER"

# Prompt the user to ask if they want to download the backup from the remote server
read -p "Do you want to download the backup from the remote server? (y/n): " download_choice

if [[ "$download_choice" == "y" || "$download_choice" == "Y" ]]; then

# Step 1: SSH into the remote server and create a backup of the database
ssh "$REMOTE_USER@$REMOTE_HOST" << EOF
# ssh deploy@3.27.57.193 << EOF
    echo "Creating backup on remote server..."

    pg_dump  $REMOTE_DB -U $REMOTE_DB_USER -h localhost > $REMOTE_BACKUP_DIR/$BACKUP_FILE
EOF

# Step 2: Copy the backup file from the remote server to the local machine
echo "Copying backup file to local machine..."
scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_BACKUP_DIR/$BACKUP_FILE" $LOCAL_BACKUP_DIR/$BACKUP_FILE
# scp deploy@3.27.57.193:~/db_dumps/database.bak ~/Desktop/database.bak

# Step 3: Delete the backup file from the remote server
ssh "$REMOTE_USER@$REMOTE_HOST" << EOF
    echo "Deleting remote backup file..."
    rm -f $REMOTE_BACKUP_DIR/$BACKUP_FILE
EOF

else
    echo "Skipping download from remote server."
fi



# # Step 4: Drop and recreate the local database
echo "Dropping and recreating local database..."
rails db:drop && rails db:create

# # Step 5: Restore the backup data to the newly created local database
# echo "Restoring backup data to local database..."
# pg_restore -U $LOCAL_DB_USER -d $LOCAL_DB -F c "$LOCAL_BACKUP_DIR/$BACKUP_FILE"
psql -d $LOCAL_DB < $LOCAL_BACKUP_DIR/$BACKUP_FILE

# # Step 6: Migrate the database
echo "Running migrations..."
rails db:migrate


# Prompt the user to ask if they want to download the backup from the remote server
read -p "Do you want to delete the backup from localhost? (y/n): " delete_choice

if [[ "$delete_choice" == "y" || "$delete_choice" == "Y" ]]; then
  # # Step 6: Delete the local backup file
  echo "Deleting local backup file..."
  rm -f "$LOCAL_BACKUP_DIR/$BACKUP_FILE"
else
  echo "skipping delete local..."
fi



echo "Database backup and restore process completed successfully!"
