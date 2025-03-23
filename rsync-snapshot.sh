#!/bin/bash

#!/bin/bash

# Get the current date in YYYY-MM-DD format
DATE=$(date +%F)
BACKUP_ROOT="/mnt/backup/snapshots"
LATEST="$BACKUP_ROOT/latest"
NEW_SNAPSHOT="$BACKUP_ROOT/$DATE"

# Ensure the backup root directory exists
sudo mkdir -p "$BACKUP_ROOT" 


# Make a new snapshot
sudo rsync -aAXv \
  --delete \
  --link-dest="$LATEST" \
  --exclude={"/mnt/backup","/proc","/tmp","/dev","/sys","/run","/mnt/films"} \
  / "$NEW_SNAPSHOT"

# Update the "latest" symlink
sudo rm -f "$LATEST"
sudo ln -s "$NEW_SNAPSHOT" "$LATEST"
