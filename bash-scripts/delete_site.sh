#!/bin/bash

CONFIG_FILE="./config.json"
SITES_FOLDER=$(jq -r '.local_settings.sites_folder' "$CONFIG_FILE")

# Function to get all sites from config.json
get_all_sites() {
    jq -r '.docker_settings.sites[].name' "$CONFIG_FILE" 2>/dev/null
}

# Function to get site details from config.json
get_site_details() {
    local site_name=$1
    jq -r --arg name "$site_name" '.docker_settings.sites[] | select(.name == $name)' "$CONFIG_FILE" 2>/dev/null
}

# Function to remove site from config.json
remove_site_from_config() {
    local site_name=$1
    local temp_file=$(mktemp)
    
    jq --arg name "$site_name" 'del(.docker_settings.sites[] | select(.name == $name))' "$CONFIG_FILE" > "$temp_file"
    mv "$temp_file" "$CONFIG_FILE"
}

# Function to delete nginx config file
delete_nginx_config() {
    local site_name=$1
    local nginx_config="docker/nginx/conf.d/${site_name}.conf"
    
    if [[ -f "$nginx_config" ]]; then
        if rm -f "$nginx_config" 2>/dev/null; then
            echo -e "\033[1;34m[Delete] Removed nginx config: $nginx_config\033[0m"
        else
            echo -e "\033[1;33m[Delete] Warning: Could not delete nginx config (may be in use)\033[0m"
            echo -e "\033[1;33m[Delete] You may need to manually delete: $nginx_config\033[0m"
        fi
    else
        echo -e "\033[1;33m[Delete] Nginx config not found: $nginx_config\033[0m"
    fi
}

# Function to delete SSL certificates
delete_ssl_certs() {
    local site_name=$1
    local ssl_cert="certs/${site_name}.crt"
    local ssl_key="certs/${site_name}.key"
    
    if [[ -f "$ssl_cert" ]]; then
        rm -f "$ssl_cert"
        echo -e "\033[1;34m[Delete] Removed SSL certificate: $ssl_cert\033[0m"
    fi
    
    if [[ -f "$ssl_key" ]]; then
        rm -f "$ssl_key"
        echo -e "\033[1;34m[Delete] Removed SSL key: $ssl_key\033[0m"
    fi
}
# Function to delete database
delete_database() {
    local site_name=$1
    local site_details=$(get_site_details "$site_name")
    local db_name=$(echo "$site_details" | jq -r '.db_name')
    local db_user=$(echo "$site_details" | jq -r '.db_user')
    local db_password=$(echo "$site_details" | jq -r '.db_password')
    
    if [[ -z "$db_name" || "$db_name" == "null" ]]; then
        echo -e "\033[1;33m[Delete] No database name found for site '$site_name'\033[0m"
        return 0
    fi
    
    echo -e "\033[1;36m[Delete] Checking if database '$db_name' exists...\033[0m"
    
    # Check if MySQL container is running
    if ! docker-compose ps -q mysql | grep -q .; then
        echo -e "\033[1;33m[Delete] Warning: MySQL container is not running. Cannot delete database.\033[0m"
        return 1
    fi
    
    # Check if database exists
    if docker exec mysql mysql -u"$db_user" -p"$db_password" -e "USE \`$db_name\`;" 2>/dev/null; then
        echo -e "\033[1;31m[Delete] Database '$db_name' exists and contains data!\033[0m"
        echo -e "\033[1;31m[Delete] This will permanently delete ALL data in the database!\033[0m"
        
        read -p $'\n\033[1;31mAre you sure you want to delete the database? (yes/no): \033[0m' db_confirmation
        
        if [[ "$db_confirmation" == "yes" ]]; then
            echo -e "\033[1;36m[Delete] Deleting database '$db_name'...\033[0m"
            if docker exec mysql mysql -u"$db_user" -p"$db_password" -e "DROP DATABASE \`$db_name\`;" 2>/dev/null; then
                echo -e "\033[1;32m[Delete] ✓ Database '$db_name' deleted successfully\033[0m"
                return 0
            else
                echo -e "\033[1;31m[Delete] ✗ Error: Failed to delete database '$db_name'\033[0m"
                return 1
            fi
        else
            echo -e "\033[1;33m[Delete] Database deletion cancelled. Database '$db_name' will remain.\033[0m"
            return 0
        fi
    else
        echo -e "\033[1;33m[Delete] Database '$db_name' does not exist or is not accessible\033[0m"
        return 0
    fi
}

# Function to clean up orphaned containers
cleanup_orphaned_containers() {
    echo -e "\033[1;36m[Delete] Checking for orphaned containers...\033[0m"
    
    # Get all PHP containers that might be orphaned
    local orphaned_containers=$(docker ps -a --filter "name=php-" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -n "$orphaned_containers" ]]; then
        for container in $orphaned_containers; do
            # Extract PHP version from container name (e.g., php-83 -> 8.3)
            local php_version=${container#php-}
            local major_version=${php_version:0:1}
            local minor_version=${php_version:1:1}
            local full_version="${major_version}.${minor_version}"
            
            # Check if this PHP version is still used in config.json
            local still_used=$(jq -r --arg version "$full_version" '.docker_settings.sites[] | select(.php_version == $version) | .name' "$CONFIG_FILE" 2>/dev/null | head -1)
            
            if [[ -z "$still_used" ]]; then
                echo -e "\033[1;34m[Delete] Removing orphaned container: $container\033[0m"
                docker rm -f "$container" 2>/dev/null
                
                # Also try to remove the associated image
                local image_name="projects-laravel_${container}"
                if docker images | grep -q "$image_name"; then
                    echo -e "\033[1;34m[Delete] Removing orphaned image: $image_name\033[0m"
                    docker rmi "$image_name" 2>/dev/null
                fi
            fi
        done
    fi
    
    echo -e "\033[1;32m[Delete] ✓ Orphaned containers cleanup completed\033[0m"
}



# Function to show site details
show_site_details() {
    local site_name=$1
    local site_details=$(get_site_details "$site_name")
    
    if [[ -n "$site_details" ]]; then
        echo -e "\n\033[1;36m=== Site Details ===\033[0m"
        echo -e "Name: $(echo "$site_details" | jq -r '.name')"
        echo -e "DNS: $(echo "$site_details" | jq -r '.server_name')"
        echo -e "Database: $(echo "$site_details" | jq -r '.db_name')"
        echo -e "PHP Version: $(echo "$site_details" | jq -r '.php_version')"
        echo -e "Path: $(echo "$site_details" | jq -r '.project_path')"
        echo -e "SSL: $(echo "$site_details" | jq -r '.ssl.enabled')"
        echo -e "\033[1;36m==================\033[0m"
    fi
}

# Function to confirm deletion
confirm_deletion() {
    local site_name=$1
    
    echo -e "\n\033[1;31m⚠️  WARNING: This will permanently delete the project!\033[0m"
    echo -e "\033[1;31mThe following will be deleted:\033[0m"
    echo -e "  • Project folder: $SITES_FOLDER/$site_name"
    echo -e "  • Nginx configuration"
    echo -e "  • SSL certificates (if any)"
    echo -e "  • Project entry from config.json"
    echo -e "  • \033[1;31mDATABASE (with separate confirmation)\033[0m"
    
    read -p $'\n\033[1;31mAre you sure you want to delete this project? (yes/no): \033[0m' confirmation
    
    if [[ "$confirmation" == "yes" ]]; then
        return 0
    else
        echo -e "\033[1;33mDeletion cancelled.\033[0m"
        return 1
    fi
}

# Main delete site function
delete_site() {
    local site_name=$1
    
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m       Delete Site: $site_name      \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    # Show site details
    show_site_details "$site_name"
    
    # Confirm deletion
    if ! confirm_deletion "$site_name"; then
        return 1
    fi
    
    echo -e "\n\033[1;36m[Delete] Starting deletion process...\033[0m"
    
    # Get site details before deletion (we'll need them for container restart)
    local site_details=$(get_site_details "$site_name")
    local php_version=$(echo "$site_details" | jq -r '.php_version')
    local php_container="php-${php_version//./}"
    
    # Check if containers need restart and stop them first
    local needs_restart=false
    if docker-compose ps -q $php_container | grep -q .; then
        echo -e "\033[1;34m[Delete] PHP container $php_container exists, stopping it first...\033[0m"
        docker-compose stop $php_container
        needs_restart=true
    else
        echo -e "\033[1;33m[Delete] PHP container $php_container not found\033[0m"
    fi
    
    # Also stop nginx if it's running to release file locks
    if docker-compose ps -q nginx | grep -q .; then
        echo -e "\033[1;34m[Delete] Stopping nginx container to release file locks...\033[0m"
        docker-compose stop nginx
    fi
    
    # Add a small delay to ensure file locks are released
    sleep 2
    
    # 1. Delete project folder
    local project_path="$SITES_FOLDER/$site_name"
    if [[ -d "$project_path" ]]; then
        echo -e "\033[1;36m[Delete] Removing project folder: $project_path\033[0m"
        if rm -rf "$project_path" 2>/dev/null; then
            echo -e "\033[1;32m[Delete] ✓ Project folder deleted\033[0m"
        else
            echo -e "\033[1;33m[Delete] Warning: Could not delete project folder (may be in use)\033[0m"
            echo -e "\033[1;33m[Delete] You may need to manually delete: $project_path\033[0m"
        fi
    else
        echo -e "\033[1;33m[Delete] Project folder not found: $project_path\033[0m"
    fi
    
    # 2. Delete nginx config
    delete_nginx_config "$site_name"
    
    # 3. Delete SSL certificates
    delete_ssl_certs "$site_name"
    
    # 4. Delete database (with confirmation)
    delete_database "$site_name"
    
    # 5. Remove from config.json
    echo -e "\033[1;36m[Delete] Removing from config.json...\033[0m"
    remove_site_from_config "$site_name"
    echo -e "\033[1;32m[Delete] ✓ Removed from config.json\033[0m"
    
    # 6. Regenerate .env file
    echo -e "\033[1;36m[Delete] Regenerating .env file...\033[0m"
    ./bash-scripts/generate_env.sh --force
    echo -e "\033[1;32m[Delete] ✓ .env file regenerated\033[0m"
    
    # 7. Regenerate docker-compose.yml
    echo -e "\033[1;36m[Delete] Regenerating docker-compose.yml...\033[0m"
    ./bash-scripts/generate_docker_compose.sh
    echo -e "\033[1;32m[Delete] ✓ docker-compose.yml regenerated\033[0m"
    
    # 8. Clean up orphaned containers
    cleanup_orphaned_containers
    
    # 9. Regenerate database config
    echo -e "\033[1;36m[Delete] Regenerating database config...\033[0m"
    ./bash-scripts/generate_database_config.sh --force
    echo -e "\033[1;32m[Delete] ✓ Database config regenerated\033[0m"
    
    # 10. Restart containers if needed
    if [[ "$needs_restart" == "true" ]]; then
        echo -e "\033[1;36m[Delete] Starting containers back up...\033[0m"
        
        # Use docker-compose down and up to avoid volume mount issues
        echo -e "\033[1;34m[Delete] Bringing down containers to clean up...\033[0m"
        docker-compose down 2>/dev/null
        
        # Start PHP container if it was running before
        if docker-compose up -d $php_container 2>/dev/null; then
            echo -e "\033[1;34m[Delete] Started PHP container: $php_container\033[0m"
        else
            echo -e "\033[1;33m[Delete] Warning: Could not start PHP container (may need manual restart)\033[0m"
            echo -e "\033[1;33m[Delete] You can manually restart with: docker-compose up -d $php_container\033[0m"
        fi
        
        # Start nginx to reload configs
        if docker-compose up -d nginx 2>/dev/null; then
            echo -e "\033[1;34m[Delete] Started nginx container\033[0m"
        else
            echo -e "\033[1;33m[Delete] Warning: Could not start nginx container (may need manual restart)\033[0m"
            echo -e "\033[1;33m[Delete] You can manually restart with: docker-compose up -d nginx\033[0m"
        fi
    else
        # If no PHP container was running, just start nginx
        if ! docker-compose ps -q nginx | grep -q .; then
            echo -e "\033[1;36m[Delete] Starting nginx container...\033[0m"
            if docker-compose up -d nginx 2>/dev/null; then
                echo -e "\033[1;34m[Delete] Started nginx container\033[0m"
            else
                echo -e "\033[1;33m[Delete] Warning: Could not start nginx container (may need manual restart)\033[0m"
                echo -e "\033[1;33m[Delete] You can manually restart with: docker-compose up -d nginx\033[0m"
            fi
        fi
    fi
    
    echo -e "\n\033[1;32m[Delete] ✓ Project '$site_name' successfully deleted!\033[0m"
    echo -e "\033[1;34m[Delete] All related files and configurations have been cleaned up.\033[0m"
}

# Main menu function
delete_site_menu() {
    clear
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m       Delete Site Menu            \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    # Get all sites
    local sites=$(get_all_sites)
    
    if [[ -z "$sites" ]]; then
        echo -e "\n\033[1;33mNo sites found in config.json\033[0m"
        read -p "Press Enter to return to the main menu..."
        return
    fi
    
    # Show sites with fzf, including back option
    local selected_site=$(printf "Back to Main Menu\n%s" "$sites" | fzf --height=15 --reverse --border --prompt "Select site to delete: ")
    
    if [[ -z "$selected_site" ]]; then
        echo -e "\n\033[1;33mNo selection made. Returning to main menu.\033[0m"
        read -p "Press Enter to continue..."
        return
    fi
    
    if [[ "$selected_site" == "Back to Main Menu" ]]; then
        echo -e "\n\033[1;34mReturning to main menu...\033[0m"
        return
    fi
    
    # Delete the selected site
    delete_site "$selected_site"
    
    read -p "Press Enter to return to the main menu..."
}

# Run the menu if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    delete_site_menu
fi
