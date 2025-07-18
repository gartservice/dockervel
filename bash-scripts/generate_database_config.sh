#!/bin/bash

CONFIG_FILE="./config.json"
DB_CONFIG_FILE="./docker/mysql/database_config.json"

FORCE=0
if [[ "$1" == "--force" ]]; then
    FORCE=1
fi

generate_database_config() {
    echo -e "\n\033[1;33mGenerating database configuration file...\033[0m"

    # Ensure the docker/mysql directory exists
    mkdir -p "./docker/mysql"

    if [ -f "$DB_CONFIG_FILE" ] && [ "$FORCE" -eq 0 ]; then
        echo -ne "\033[1;31mWarning: $DB_CONFIG_FILE already exists. Overwrite? (y/n): \033[0m"; read CONFIRM
        if [[ "$CONFIRM" != "y" ]]; then
            echo -e "\n\033[1;33mOperation cancelled. $DB_CONFIG_FILE was not modified.\033[0m"
            return
        fi
    fi

    # Extract only database names and create a simple array
    jq -r '.docker_settings.sites[].db_name' "$CONFIG_FILE" | jq -R -s 'split("\n")[:-1]' > "$DB_CONFIG_FILE"

    echo -e "\033[1;32mDatabase configuration file created: $DB_CONFIG_FILE\033[0m"
}

# Execute function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_database_config "$@"
fi 