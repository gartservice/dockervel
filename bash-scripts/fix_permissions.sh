#!/bin/bash

# Path to your Laravel project root
LARAVEL_ROOT="."

# Web server group (usually www-data on Ubuntu)
WEB_GROUP="www-data"

# Add your user to the web server group
# (Only needs to be done once. You may need to re-login after this.)
sudo usermod -a -G $WEB_GROUP $USER

# Set folder permissions: owner can read/write/execute, group can read/execute
echo "Fixing directory permissions..."
find $LARAVEL_ROOT -type d -exec chmod 755 {} \;

# Set file permissions: owner can read/write, group can read
echo "Fixing file permissions..."
find $LARAVEL_ROOT -type f -exec chmod 644 {} \;

# Give group write access to necessary Laravel folders
echo "Giving group write access to storage and bootstrap/cache..."
sudo chmod -R g+rwX $LARAVEL_ROOT/storage $LARAVEL_ROOT/bootstrap/cache

# Set group ownership to web group for writable folders
echo "Setting group to $WEB_GROUP for writable folders..."
sudo chgrp -R $WEB_GROUP $LARAVEL_ROOT/storage $LARAVEL_ROOT/bootstrap/cache

echo "✅ Done. Your user keeps ownership, and Laravel works!"
