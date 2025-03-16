#!/bin/bash

CONFIG_FILE="./config.json"

# Ensure the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found!"
    exit 1
fi

# project locations
SITES_FOLDER=$(jq -r '.local_settings.sites_folder' "$CONFIG_FILE")
# Extract MySQL settings
MYSQL_CONTAINER=$(jq -r '.docker_settings.mysql.container_name' "$CONFIG_FILE")
MYSQL_ROOT_PASSWORD=$(jq -r '.docker_settings.mysql.root_password' "$CONFIG_FILE")

# Extract Nginx settings
NGINX_CONTAINER=$(jq -r '.docker_settings.nginx.container_name' "$CONFIG_FILE")
NGINX_HTTP_PORT=$(jq -r '.docker_settings.nginx.http_port' "$CONFIG_FILE")
NGINX_HTTPS_PORT=$(jq -r '.docker_settings.nginx.https_port' "$CONFIG_FILE")
SSL_CERT=$(jq -r '.docker_settings.nginx.ssl.cert' "$CONFIG_FILE")
SSL_KEY=$(jq -r '.docker_settings.nginx.ssl.key' "$CONFIG_FILE")

# Extract required packages
REQUIRED_PACKAGES=$(jq -r '.local_settings.required_packages[]' "$CONFIG_FILE")

# Extract available PHP versions
AVAILABLE_PHP_VERSIONS=$(jq -r '.local_settings.available_php_versions[]' "$CONFIG_FILE")

# Extract Cloudflare settings
CLOUDFLARE_EMAIL=$(jq -r '.local_settings.cloudflare.email' "$CONFIG_FILE")
CLOUDFLARE_API_KEY=$(jq -r '.local_settings.cloudflare.api_key' "$CONFIG_FILE")
CLOUDFLARE_ZONE_ID=$(jq -r '.local_settings.cloudflare.zone_id' "$CONFIG_FILE")

# Extract and loop through sites
# echo -e "\n\033[1;34mConfigured Sites:\033[0m"
# jq -c '.docker_settings.sites[]' "$CONFIG_FILE" | while read -r site; do
#     SITE_NAME=$(echo "$site" | jq -r '.name')
#     ROOT_PATH=$(echo "$site" | jq -r '.root')
#     SERVER_NAME=$(echo "$site" | jq -r '.server_name')
#     DB_NAME=$(echo "$site" | jq -r '.db_name')
#     DB_USER=$(echo "$site" | jq -r '.db_user')
#     DB_PASSWORD=$(echo "$site" | jq -r '.db_password')
#     PHP_VERSION=$(echo "$site" | jq -r '.php_version')

#     echo -e "\033[1;33m- $SITE_NAME\033[0m (Server: $SERVER_NAME, DB: $DB_NAME, PHP: $PHP_VERSION)"
# done

# Extract available commands
# echo -e "\n\033[1;34mAvailable Commands:\033[0m"
# jq -r '.local_settings.available_commands | to_entries[] | "\(.key): \(.value[0])"' "$CONFIG_FILE"

# Example of running one of the commands
# echo -e "\n\033[1;32mRunning database migration:\033[0m"
# COMMAND_TO_RUN=$(jq -r '.local_settings.available_commands["run migrations"][0]' "$CONFIG_FILE")
# eval "$COMMAND_TO_RUN"
