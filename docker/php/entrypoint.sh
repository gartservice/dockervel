#!/bin/sh

echo "Running Laravel migrations..."

php artisan migrate --force

echo "Starting PHP-FPM..."
exec php-fpm
