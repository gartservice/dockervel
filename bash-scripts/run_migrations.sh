#!/bin/bash

CONFIG_FILE="./config.json"

# Function to get all Laravel sites from config.json
get_laravel_sites() {
    jq -r '.docker_settings.sites[].name' "$CONFIG_FILE" 2>/dev/null
}

# Function to run migrations for a specific site
run_migrations_for_site() {
    local site_name=$1
    local site_details=$(jq -r --arg name "$site_name" '.docker_settings.sites[] | select(.name == $name)' "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -z "$site_details" ]]; then
        echo -e "\033[1;31mError: Site '$site_name' not found in config.json\033[0m"
        return 1
    fi
    
    local php_version=$(echo "$site_details" | jq -r '.php_version')
    local php_container="php-${php_version//./}"
    
    echo -e "\033[1;36m[${site_name}] Running migrations for $site_name (PHP $php_version)...\033[0m"
    
    # Check if container is running
    if ! docker-compose ps -q $php_container | grep -q .; then
        echo -e "\033[1;31m[${site_name}] Error: PHP container $php_container is not running\033[0m"
        return 1
    fi
    
    # Check if artisan file exists
    if ! docker exec $php_container test -f "/var/www/html/$site_name/artisan"; then
        echo -e "\033[1;33m[${site_name}] Warning: No artisan file found. This may not be a Laravel project.\033[0m"
        return 1
    fi
    
    # Run migrations
    if docker exec $php_container php "/var/www/html/$site_name/artisan" migrate --force; then
        echo -e "\033[1;32m[${site_name}] ✓ Migrations completed successfully\033[0m"
        return 0
    else
        echo -e "\033[1;31m[${site_name}] ✗ Migrations failed\033[0m"
        return 1
    fi
}

# Function to show migration menu
show_migration_menu() {
    clear
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m       Database Migrations Menu     \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    # Get all sites
    local sites=$(get_laravel_sites)
    
    if [[ -z "$sites" ]]; then
        echo -e "\n\033[1;33mNo sites found in config.json\033[0m"
        read -p "Press Enter to return to the main menu..."
        return
    fi
    
    # Show sites with fzf, including back option and "All Sites" option
    local selected_site=$(printf "Back to Main Menu\nAll Sites\n%s" "$sites" | fzf --height=15 --reverse --border --prompt "Select site to run migrations: ")
    
    if [[ -z "$selected_site" ]]; then
        echo -e "\n\033[1;33mNo selection made. Returning to main menu.\033[0m"
        read -p "Press Enter to continue..."
        return
    fi
    
    if [[ "$selected_site" == "Back to Main Menu" ]]; then
        echo -e "\n\033[1;34mReturning to main menu...\033[0m"
        return
    fi
    
    if [[ "$selected_site" == "All Sites" ]]; then
        echo -e "\n\033[1;36mRunning migrations for all sites...\033[0m"
        local success_count=0
        local total_count=0
        
        while IFS= read -r site_name; do
            if [[ -n "$site_name" ]]; then
                ((total_count++))
                if run_migrations_for_site "$site_name"; then
                    ((success_count++))
                fi
            fi
        done <<< "$sites"
        
        echo -e "\n\033[1;36mMigration Summary:\033[0m"
        echo -e "\033[1;32m✓ Successful: $success_count\033[0m"
        echo -e "\033[1;31m✗ Failed: $((total_count - success_count))\033[0m"
        echo -e "\033[1;34mTotal: $total_count\033[0m"
    else
        # Run migrations for selected site
        run_migrations_for_site "$selected_site"
    fi
    
    read -p "Press Enter to return to the main menu..."
}

# Function to run migrations for a specific site (for direct script calls)
run_migrations_direct() {
    local site_name=$1
    
    if [[ -z "$site_name" ]]; then
        echo -e "\033[1;31mError: Please provide a site name\033[0m"
        echo -e "Usage: $0 <site_name>"
        echo -e "   or: $0 (for interactive menu)"
        exit 1
    fi
    
    run_migrations_for_site "$site_name"
}

# Run the menu if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 1 ]]; then
        run_migrations_direct "$1"
    else
        show_migration_menu
    fi
fi
