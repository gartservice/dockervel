#!/bin/bash

CONFIG_FILE="./config.json"
ENV_FILE="./.env"

echo "Generating .env file from config.json..."

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

echo ".env file created!"
