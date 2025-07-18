#!/bin/bash

source "./bash-scripts/parse_config.sh"

run_migrations() {
    while true; do
        echo -e "\n\033[1;34mSelect a site to run migrations (or go back):\033[0m"

        # Get all site names from config.json and add "Back to Main Menu" option
        SITES=$(jq -r '.docker_settings.sites[].name' ./config.json)
        OPTIONS=($SITES "Back to Main Menu")

        # Let user pick a site
        SELECTED_SITE=$(printf "%s\n" "${OPTIONS[@]}" | fzf --height=10 --reverse --border)

        if [[ "$SELECTED_SITE" == "Back to Main Menu" ]]; then
            return  # Exits the function and returns to main menu
        fi

        if [ -z "$SELECTED_SITE" ]; then
            echo -e "\n\033[1;31mNo site selected. Returning to main menu.\033[0m"
            return
        fi

        # Get PHP container name and project path for the selected site
        PHP_CONTAINER=$(jq -r --arg SITE "$SELECTED_SITE" '.docker_settings.sites[] | select(.name==$SITE) | .php_container' ./config.json)
        PROJECT_PATH=$(jq -r --arg SITE "$SELECTED_SITE" '.docker_settings.sites[] | select(.name==$SITE) | .project_path' ./config.json)

        if [ -z "$PHP_CONTAINER" ]; then
            echo -e "\n\033[1;31mPHP container not found for $SELECTED_SITE.\033[0m"
            return
        fi

        if [ -z "$PROJECT_PATH" ]; then
            echo -e "\n\033[1;31mProject path not found for $SELECTED_SITE.\033[0m"
            return
        fi

        echo -e "\n\033[1;34mRunning migrations for $SELECTED_SITE inside container: $PHP_CONTAINER at path: $PROJECT_PATH...\033[0m"
        docker exec -it "$PHP_CONTAINER" bash -c "cd $PROJECT_PATH && php artisan migrate --force"
        echo -e "\033[1;32mMigrations completed for $SELECTED_SITE.\033[0m"
        read -p "Press Enter to continue..."
    done
}
