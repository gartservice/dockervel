#!/bin/bash

CONFIG_FILE="./config.json"
ENV_FILE=".env"

FORCE=0
if [[ "$1" == "--force" ]]; then
    FORCE=1
fi

generate_env_file() {
    echo -e "\n\033[1;33mGenerating .env file from config.json...\033[0m"

    if [ -f "$ENV_FILE" ] && [ "$FORCE" -eq 0 ]; then
        echo -ne "\033[1;31mWarning: .env file already exists. Overwrite? (y/n): \033[0m"; read CONFIRM
        if [[ "$CONFIRM" != "y" ]]; then
            echo -e "\n\033[1;33mOperation cancelled. .env file was not modified.\033[0m"
            return
        fi
    fi

    echo "MYSQL_CONTAINER=$(jq -r '.docker_settings.mysql.container_name' "$CONFIG_FILE")" > "$ENV_FILE"
    echo "MYSQL_ROOT_PASSWORD=$(jq -r '.docker_settings.mysql.root_password' "$CONFIG_FILE")" >> "$ENV_FILE"

    echo "NGINX_CONTAINER=$(jq -r '.docker_settings.nginx.container_name' "$CONFIG_FILE")" >> "$ENV_FILE"
    echo "NGINX_HTTP_PORT=$(jq -r '.docker_settings.nginx.http_port' "$CONFIG_FILE")" >> "$ENV_FILE"
    echo "NGINX_HTTPS_PORT=$(jq -r '.docker_settings.nginx.https_port' "$CONFIG_FILE")" >> "$ENV_FILE"
    echo "SSL_CERT=$(jq -r '.docker_settings.nginx.ssl.cert' "$CONFIG_FILE")" >> "$ENV_FILE"
    echo "SSL_KEY=$(jq -r '.docker_settings.nginx.ssl.key' "$CONFIG_FILE")" >> "$ENV_FILE"

    echo "CLOUDFLARE_EMAIL=$(jq -r '.local_settings.cloudflare.email' "$CONFIG_FILE")" >> "$ENV_FILE"
    echo "CLOUDFLARE_API_KEY=$(jq -r '.local_settings.cloudflare.api_key' "$CONFIG_FILE")" >> "$ENV_FILE"
    echo "CLOUDFLARE_ZONE_ID=$(jq -r '.local_settings.cloudflare.zone_id' "$CONFIG_FILE")" >> "$ENV_FILE"

    # Add backend/frontend networks
    echo "BACKEND_NETWORK=$(jq -r '.docker_settings.networks.backend_network' "$CONFIG_FILE")" >> "$ENV_FILE"
    echo "FRONTEND_NETWORK=$(jq -r '.docker_settings.networks.frontend_network' "$CONFIG_FILE")" >> "$ENV_FILE"

    # Add DB values for each site
    echo -e "\n# Site-specific database variables" >> "$ENV_FILE"
    jq -c '.docker_settings.sites[]' "$CONFIG_FILE" | while read -r site; do
        NAME=$(echo "$site" | jq -r '.name')
        DB_NAME=$(echo "$site" | jq -r '.db_name')
        DB_USER=$(echo "$site" | jq -r '.db_user')
        DB_PASSWORD=$(echo "$site" | jq -r '.db_password')

        # Normalize name to uppercase and replace `-` with `_`
        VAR_PREFIX=$(echo "$NAME" | tr '[:lower:]-' '[:upper:]_')

        echo "${VAR_PREFIX}_DB_NAME=$DB_NAME" >> "$ENV_FILE"
        echo "${VAR_PREFIX}_DB_USER=$DB_USER" >> "$ENV_FILE"
        echo "${VAR_PREFIX}_DB_PASSWORD=$DB_PASSWORD" >> "$ENV_FILE"
    done

    echo -e "\n\033[1;32m.env file created successfully!\033[0m"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_env_file "$@"
fi