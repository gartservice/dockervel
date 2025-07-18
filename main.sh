#!/bin/bash

# Load function files
source "./bash-scripts/utils.sh"
source "./bash-scripts/build_docker.sh"
source "./bash-scripts/run_migrations.sh"
source "./bash-scripts/initialize_database.sh"
source "./bash-scripts/check_required_apps.sh"
source "./bash-scripts/generate_env.sh"
source "./bash-scripts/add_site.sh"
source "./bash-scripts/generate_docker_compose.sh"
source "./bash-scripts/generate_nginx_confs.sh"
source "./bash-scripts/generate_config.sh"
source "./bash-scripts/generate_database_config.sh"
source "./bash-scripts/delete_site.sh"
source "./bash-scripts/fix_permissions.sh"

# Ensure fzf is installed
ensure_fzf_installed

# Function to show the main menu
show_menu() {
    options=("Add New Site"
     "Delete Existing Site"
     "Fix Laravel Permissions"
     "Build Docker Containers"
     "Init databases"
     "Run Migrations"
     "Check Required Applications"
     "Generate .env File"
     "Generate docker-compose file"
     "Generate nginx config files"
     "Generate config.json from template"
     "Generate database_config.json from config.json"
     "Exit")
    while true; do
        clear
        echo -e "\n\033[1;36m================================\033[0m"
        echo -e "\033[1;36m        Main Bash Menu         \033[0m"
        echo -e "\033[1;36m================================\033[0m"
        echo -e "\n\033[1;33mUse arrow keys to navigate and Enter to select:\033[0m"

        choice=$(printf "%s\n" "${options[@]}" | fzf --height=80% --reverse --border=sharp)

        case "$choice" in
            "Add New Site") add_new_site; read -p "Press Enter to continue..." ;;
            "Delete Existing Site") delete_site_menu; read -p "Press Enter to continue..." ;;
            "Fix Laravel Permissions") show_permissions_menu; read -p "Press Enter to continue..." ;;
            "Build Docker Containers") build_docker_containers; read -p "Press Enter to continue..." ;;
            "Init databases") initialize_database; read -p "Press Enter to continue..." ;;
            "Run Migrations") run_migrations; read -p "Press Enter to continue..." ;;
            "Check Required Applications") check_all_apps; read -p "Press Enter to continue..." ;;
            "Generate .env File") generate_env_file; read -p "Press Enter to continue..." ;;
            "Generate docker-compose file") generate_compose_file; read -p "Press Enter to continue..." ;;
            "Generate nginx config files") generate_nginx_confs; read -p "Press Enter to continue..." ;;
            "Generate config.json from template") generate_config_json; read -p "Press Enter to continue..." ;;
            "Generate database_config.json from config.json") generate_database_config; read -p "Press Enter to continue..." ;;
            "Exit") exit 0 ;;
        esac
    done
}

# Start the interactive menu
show_menu
