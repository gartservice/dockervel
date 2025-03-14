#!/bin/bash

echo "Checking and creating databases if needed..."

# Load the JSON file and parse it using jq
CONFIG_FILE="/config.json"

# Read databases array from JSON and store it in a Bash array
DATABASES=($(jq -r '.databases[]' "$CONFIG_FILE"))

DB_HOST="mysql"
DB_USER="root"
DB_PASS="${MYSQL_ROOT_PASSWORD}"

# Wait for MySQL to start with improved error checking
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1" > /dev/null 2>&1; do
    echo "Waiting for MySQL..."
    sleep 2
done

# Create databases if they do not exist with error checking
for db in "${DATABASES[@]}"; do
    echo "Checking database: $db"
    if ! mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $db;"; then
        echo "Error creating database $db"
    fi
done

echo "Database initialization complete."