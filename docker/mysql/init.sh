#!/bin/bash

echo "Checking and creating databases if needed..."

DB_HOST="mysql"
DB_USER="root"
DB_PASS="${MYSQL_ROOT_PASSWORD}"

# Wait for MySQL to start
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1"; do
    echo "Waiting for MySQL..."
    sleep 2
done

# Create databases if they do not exist
for db in site1_db site2_db; do
    echo "Checking database: $db"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $db;"
done

echo "Database initialization complete."
