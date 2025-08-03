#!/bin/bash

SITE_NAME="$1"
CONFIG_FILE="./config.json"
SITES_FOLDER=$(jq -r '.local_settings.sites_folder' "$CONFIG_FILE")
SITE_PATH="$SITES_FOLDER/$SITE_NAME"

if [ ! -f "$SITE_PATH/.env" ]; then
    echo "No .env file found for $SITE_NAME"
    exit 1
fi

# Extract DB settings from config.json
DB_NAME=$(jq -r --arg name "$SITE_NAME" '.docker_settings.sites[] | select(.name==$name) | .db_name' "$CONFIG_FILE")
DB_USER=$(jq -r --arg name "$SITE_NAME" '.docker_settings.sites[] | select(.name==$name) | .db_user' "$CONFIG_FILE")
DB_PASSWORD=$(jq -r --arg name "$SITE_NAME" '.docker_settings.sites[] | select(.name==$name) | .db_password' "$CONFIG_FILE")

# Remove all DB_* lines (commented or not, with or without spaces)
sed -i '/^[[:space:]]*#*[[:space:]]*DB_CONNECTION=/Id' "$SITE_PATH/.env"
sed -i '/^[[:space:]]*#*[[:space:]]*DB_HOST=/Id' "$SITE_PATH/.env"
sed -i '/^[[:space:]]*#*[[:space:]]*DB_PORT=/Id' "$SITE_PATH/.env"
sed -i '/^[[:space:]]*#*[[:space:]]*DB_DATABASE=/Id' "$SITE_PATH/.env"
sed -i '/^[[:space:]]*#*[[:space:]]*DB_USERNAME=/Id' "$SITE_PATH/.env"
sed -i '/^[[:space:]]*#*[[:space:]]*DB_PASSWORD=/Id' "$SITE_PATH/.env"

# Add correct, uncommented lines at the end
echo "DB_CONNECTION=mysql" >> "$SITE_PATH/.env"
echo "DB_HOST=mysql" >> "$SITE_PATH/.env"
echo "DB_PORT=3306" >> "$SITE_PATH/.env"
echo "DB_DATABASE=$DB_NAME" >> "$SITE_PATH/.env"
echo "DB_USERNAME=$DB_USER" >> "$SITE_PATH/.env"
echo "DB_PASSWORD=$DB_PASSWORD" >> "$SITE_PATH/.env"

echo "Cleaned and updated $SITE_PATH/.env to use MySQL settings from config.json (no duplicates, no commented DB_* lines)" 