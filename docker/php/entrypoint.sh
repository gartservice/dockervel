#!/bin/bash

set -e
cd "${APP_DIR}"
echo "Setting permissions for Laravel..."
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# # Wait until MySQL is available
# echo "Waiting for MySQL to be ready..."
# until mysqladmin ping -h mysql --silent; do
#     sleep 1
# done

# Generate .env and app key if not already present
if [ ! -f ".env" ]; then
    echo "Generating .env file and app key..."
    cp .env.example .env
    php artisan key:generate

    echo "Running Laravel migrations (first time only)..."
    php artisan migrate --force
fi

# Start PHP-FPM as the main process
echo "Starting PHP-FPM..."
exec php-fpm
