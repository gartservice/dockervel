#!/bin/bash

CONFIG_FILE="./config.json"
SITES_FOLDER=$(jq -r '.local_settings.sites_folder' "$CONFIG_FILE")

# Function to fix permissions for a specific Laravel project
fix_laravel_permissions() {
    local project_path="$1"
    local project_name="$2"
    
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m    Fixing Permissions for $project_name\033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    # Web server group (usually www-data on Ubuntu)
    WEB_GROUP="www-data"
    
    # Check if project path exists
    if [[ ! -d "$project_path" ]]; then
        echo -e "\033[1;31mError: Project path '$project_path' does not exist!\033[0m"
        return 1
    fi
    
    # Check if it's a Laravel project
    if [[ ! -f "$project_path/artisan" ]]; then
        echo -e "\033[1;33mWarning: This doesn't appear to be a Laravel project (no artisan file found).\033[0m"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Add your user to the web server group (only needs to be done once)
    echo -e "\033[1;34mAdding user to $WEB_GROUP group (if not already added)...\033[0m"
    sudo usermod -a -G $WEB_GROUP $USER 2>/dev/null || true
    
    # Set folder permissions: owner can read/write/execute, group can read/execute
    echo -e "\033[1;34mFixing directory permissions...\033[0m"
    find "$project_path" -type d -exec chmod 755 {} \;
    
    # Set file permissions: owner can read/write, group can read
    echo -e "\033[1;34mFixing file permissions...\033[0m"
    find "$project_path" -type f -exec chmod 644 {} \;
    
    # Give group write access to necessary Laravel folders
    echo -e "\033[1;34mGiving group write access to storage and bootstrap/cache...\033[0m"
    if [[ -d "$project_path/storage" ]]; then
        sudo chmod -R g+rwX "$project_path/storage"
        sudo chgrp -R $WEB_GROUP "$project_path/storage"
    fi
    
    if [[ -d "$project_path/bootstrap/cache" ]]; then
        sudo chmod -R g+rwX "$project_path/bootstrap/cache"
        sudo chgrp -R $WEB_GROUP "$project_path/bootstrap/cache"
    fi
    
    # Make artisan executable
    if [[ -f "$project_path/artisan" ]]; then
        chmod +x "$project_path/artisan"
        echo -e "\033[1;34mMade artisan executable.\033[0m"
    fi
    
    echo -e "\033[1;32m✅ Permissions fixed for $project_name!\033[0m"
    echo -e "\033[1;33mNote: You may need to re-login for group changes to take effect.\033[0m"
}

# Function to show the permissions menu
show_permissions_menu() {
    clear
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m       Fix Permissions Menu         \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    # Get all sites from config.json
    local sites=$(jq -r '.docker_settings.sites[].name' "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -z "$sites" ]]; then
        echo -e "\n\033[1;33mNo sites found in config.json.\033[0m"
        read -p "Press Enter to return to the main menu..."
        return
    fi
    
    echo -e "\n\033[1;33mSelect a project to fix permissions:\033[0m"
    
    local selected_site=$(printf "Back to Main Menu\nAll Laravel Projects\n%s" "$sites" | fzf --height=15 --reverse --border --prompt "Select project to fix permissions: ")
    
    if [[ -z "$selected_site" ]]; then
        echo -e "\n\033[1;33mNo selection made. Returning to main menu.\033[0m"
        return
    fi
    
    if [[ "$selected_site" == "Back to Main Menu" ]]; then
        echo -e "\n\033[1;34mReturning to main menu...\033[0m"
        return
    fi
    
    if [[ "$selected_site" == "All Laravel Projects" ]]; then
        echo -e "\n\033[1;36mFixing permissions for all Laravel projects...\033[0m"
        while IFS= read -r site_name; do
            local site_path="$SITES_FOLDER/$site_name"
            if [[ -d "$site_path" ]]; then
                fix_laravel_permissions "$site_path" "$site_name"
            fi
        done <<< "$sites"
        echo -e "\n\033[1;32m✅ All Laravel projects processed!\033[0m"
    else
        # Construct the local project path using sites_folder and site name
        local project_path="$SITES_FOLDER/$selected_site"
        
        if [[ ! -d "$project_path" ]]; then
            echo -e "\033[1;31mError: Project path '$project_path' does not exist!\033[0m"
            read -p "Press Enter to return to the main menu..."
            return
        fi
        
        fix_laravel_permissions "$project_path" "$selected_site"
    fi
    
    read -p "Press Enter to return to the main menu..."
}

# Function to fix permissions for a specific site (for use in add_site.sh)
fix_permissions_for_site() {
    local site_name="$1"
    local project_path="$2"
    
    if [[ -z "$site_name" || -z "$project_path" ]]; then
        echo -e "\033[1;31mError: Site name and project path are required.\033[0m"
        return 1
    fi
    
    fix_laravel_permissions "$project_path" "$site_name"
}

# Show usage information
show_usage() {
    echo -e "Usage: $0 [OPTIONS]"
    echo -e ""
    echo -e "Options:"
    echo -e "  --site SITE_NAME --path PROJECT_PATH    Fix permissions for specific site"
    echo -e "  --help, -h                              Show this help message"
    echo -e ""
    echo -e "Examples:"
    echo -e "  $0                                    # Interactive menu"
    echo -e "  $0 --site mysite --path /path/to/site # Fix permissions for specific site"
    echo -e ""
}

# Parse command line arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        --site)
            if [[ $# -lt 4 ]]; then
                echo -e "\033[1;31mError: --site requires --path argument\033[0m"
                show_usage
                exit 1
            fi
            SITE_NAME="$2"
            PROJECT_PATH="$4"
            fix_permissions_for_site "$SITE_NAME" "$PROJECT_PATH"
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo -e "\033[1;31mError: Unknown option '$1'\033[0m"
            show_usage
            exit 1
            ;;
    esac
elif [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Run the menu if script is executed directly (not sourced)
    show_permissions_menu
fi
