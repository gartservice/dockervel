#!/bin/bash

CONFIG_FILE="./config.json"

echo -e "\033[1;33mUpdating existing sites configuration with new fields...\033[0m"

# Create a temporary file for the updated config
TEMP_CONFIG=$(mktemp)

# Update each site to include php_container and project_path
jq '
  .docker_settings.sites |= map(
    . + {
      php_container: ("php-" + (.php_version | gsub("\\."; ""))),
      project_path: ("/var/www/html/" + .name)
    }
  )
' "$CONFIG_FILE" > "$TEMP_CONFIG"

# Replace the original config file
mv "$TEMP_CONFIG" "$CONFIG_FILE"

echo -e "\033[1;32mExisting sites configuration updated successfully!\033[0m"
echo -e "\033[1;34mAdded fields to all sites:\033[0m"
echo -e "  - php_container: PHP container name (e.g., php-84)"
echo -e "  - project_path: Path inside container (e.g., /var/www/html/sitename)" 