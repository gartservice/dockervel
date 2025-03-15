#!/bin/bash

# Define the container name for the database
DB_CONTAINER="my_database_container"
DB_INIT_SCRIPT="/path/to/databases/init.sh"

# Define the container name for the application
APP_CONTAINER="my_application_container"

# Function to initialize the database
initialize_database() {
    echo -e "\n\033[1;34mInitializing database inside container: $DB_CONTAINER...\033[0m"
    docker exec -it "$DB_CONTAINER" bash -c "$DB_INIT_SCRIPT"
    echo -e "\033[1;32mDatabase initialization completed.\033[0m"
}

# Function to run migrations
run_migrations() {
    echo -e "\n\033[1;34mRunning migrations inside application container: $APP_CONTAINER...\033[0m"
    docker exec -it "$APP_CONTAINER" bash -c "php artisan migrate --force"
    echo -e "\033[1;32mMigrations completed.\033[0m"
}

# Function to display the menu
show_menu() {
    options=("Initialize Database" "Run Migrations" "Exit")
    while true; do
        clear
        echo -e "\n\033[1;36m================================\033[0m"
        echo -e "\033[1;36m  Container Database Manager \033[0m"
        echo -e "\033[1;36m================================\033[0m"
        echo -e "\n\033[1;33mUse arrow keys to navigate and Enter to select:\033[0m"
        choice=$(printf "%s\n" "${options[@]}" | fzf --height=10 --reverse --border)
        case "$choice" in
            "Initialize Database") initialize_database; read -p "Press Enter to continue..." ;;
            "Run Migrations") run_migrations; read -p "Press Enter to continue..." ;;
            "Exit") exit 0 ;;
        esac
    done
}

# Ensure fzf is installed
if ! command -v fzf &> /dev/null; then
    echo -e "\n\033[1;31mfzf is required for interactive menu. Installing...\033[0m"
    sudo apt update && sudo apt install -y fzf
fi

# Start interactive menu
show_menu
