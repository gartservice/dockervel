#!/bin/bash

# Load function files
source "./bash-scripts/utils.sh"
source "./bash-scripts/build_docker.sh"
source "./bash-scripts/run_migrations.sh"
source "./bash-scripts/initialize_database.sh"
source "./bash-scripts/check_required_apps.sh"
source "./bash-scripts/generate_env.sh"

# Ensure fzf is installed
ensure_fzf_installed

# Function to show the main menu
show_menu() {
    options=("Build Docker Containers" "Init databases" "Run Migrations" "Check Required Applications" "Generate .env File" "Exit")
    while true; do
        clear
        echo -e "\n\033[1;36m================================\033[0m"
        echo -e "\033[1;36m        Main Bash Menu         \033[0m"
        echo -e "\033[1;36m================================\033[0m"
        echo -e "\n\033[1;33mUse arrow keys to navigate and Enter to select:\033[0m"

        choice=$(printf "%s\n" "${options[@]}" | fzf --height=10 --reverse --border)

        case "$choice" in
            "Build Docker Containers") build_docker_containers; read -p "Press Enter to continue..." ;;
            "Init databases") initialize_database; read -p "Press Enter to continue..." ;;
            "Run Migrations") run_migrations; read -p "Press Enter to continue..." ;;
            "Check Required Applications") check_all_apps; read -p "Press Enter to continue..." ;;
            "Generate .env File") generate_env_file; read -p "Press Enter to continue..." ;;
            "Exit") exit 0 ;;
        esac
    done
}

# Start the interactive menu
show_menu
