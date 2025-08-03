#!/bin/bash

# Source all the required scripts to access their functions
source "$(dirname "$0")/fix_permissions.sh"
source "$(dirname "$0")/build_docker.sh"
source "$(dirname "$0")/initialize_database.sh"
source "$(dirname "$0")/run_migrations.sh"
source "$(dirname "$0")/generate_env.sh"
source "$(dirname "$0")/generate_docker_compose.sh"
source "$(dirname "$0")/generate_nginx_confs.sh"
source "$(dirname "$0")/generate_database_config.sh"

# Function to show the manual scripts submenu
show_manual_scripts_menu() {
    clear
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m      Manual Scripts & Debug Menu    \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    echo -e "\n\033[1;33mThese scripts are typically run automatically in the background.\033[0m"
    echo -e "\033[1;33mUse this menu for manual execution, debugging, or testing.\033[0m"
    
    optionsManual=("Fix Laravel Permissions"
             "Build Docker Containers"
             "Init databases"
             "Run Migrations"
             "Generate .env File"
             "Generate docker-compose file"
             "Generate nginx config files"
             "Generate database_config.json from config.json"
             "Back to Main Menu")
    
    echo -e "\n\033[1;33mSelect an option:\033[0m"
    
    choiceManual=$(printf "%s\n" "${optionsManual[@]}" | fzf --height=15 --reverse --border --prompt "Manual Scripts Menu: ")
    
    case "$choiceManual" in
        "Fix Laravel Permissions")
            show_permissions_menu
            read -p "Press Enter to continue..."
            ;;
        "Build Docker Containers")
            build_docker_containers
            read -p "Press Enter to continue..."
            ;;
        "Init databases")
            initialize_database
            read -p "Press Enter to continue..."
            ;;
        "Run Migrations")
            show_migration_menu
            read -p "Press Enter to continue..."
            ;;
        "Generate .env File")
            generate_env_file
            read -p "Press Enter to continue..."
            ;;
        "Generate docker-compose file")
            generate_compose_file
            read -p "Press Enter to continue..."
            ;;
        "Generate nginx config files")
            generate_nginx_confs
            read -p "Press Enter to continue..."
            ;;
        "Generate database_config.json from config.json")
            generate_database_config
            read -p "Press Enter to continue..."
            ;;
        "Back to Main Menu")            
            return
            ;;
        *) exit 0 ;;            
    esac
}

# Execute function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_manual_scripts_menu "$@"
fi 