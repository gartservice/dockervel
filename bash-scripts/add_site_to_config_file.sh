#!/bin/bash

CONFIG_FILE="./config.json"

SITE_NAME=$1
SITE_PATH=$2
SITE_DNS=$3
DB_NAME=$4
DB_USER=$5
DB_PASSWORD=$6
PHP_VERSION=$7

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "\033[1;31mError: Configuration file $CONFIG_FILE not found!\033[0m"
    exit 1
fi

# Create a new JSON entry for the site
NEW_SITE=$(jq -n \
    --arg name "$SITE_NAME" \
    --arg root "$SITE_NAME" \
    --arg server_name "$SITE_DNS" \
    --arg db_name "$DB_NAME" \
    --arg db_user "$DB_USER" \
    --arg db_password "$DB_PASSWORD" \
    --arg php_version "$PHP_VERSION" \
    '{name: $name, root: $root, server_name: $server_name, db_name: $db_name, db_user: $db_user, db_password: $db_password, php_version: $php_version}')

# Add the new site entry to the "sites" array in the JSON file
jq --argjson new_site "$NEW_SITE" '.docker_settings.sites += [$new_site]' "$CONFIG_FILE" > temp.json && mv temp.json "$CONFIG_FILE"

echo -e "\033[1;32mSite $SITE_NAME successfully added to configuration!\033[0m"
