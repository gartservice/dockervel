#!/bin/bash

CONFIG_FILE="./config.json"

# Function to clean up orphaned containers
cleanup_orphaned_containers() {
    echo -e "\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m    Cleanup Orphaned Containers    \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    echo -e "\033[1;36m[Cleanup] Checking for orphaned containers...\033[0m"
    
    # Get all PHP containers that might be orphaned
    local orphaned_containers=$(docker ps -a --filter "name=php-" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$orphaned_containers" ]]; then
        echo -e "\033[1;32m[Cleanup] No PHP containers found.\033[0m"
        return 0
    fi
    
    local found_orphans=false
    
    for container in $orphaned_containers; do
        # Extract PHP version from container name (e.g., php-83 -> 8.3)
        local php_version=${container#php-}
        local major_version=${php_version:0:1}
        local minor_version=${php_version:1:1}
        local full_version="${major_version}.${minor_version}"
        
        # Check if this PHP version is still used in config.json
        local still_used=$(jq -r --arg version "$full_version" '.docker_settings.sites[] | select(.php_version == $version) | .name' "$CONFIG_FILE" 2>/dev/null | head -1)
        
        if [[ -z "$still_used" ]]; then
            found_orphans=true
            echo -e "\033[1;34m[Cleanup] Found orphaned container: $container (PHP $full_version)\033[0m"
            
            # Ask for confirmation
            read -p $'\033[1;31mRemove this container? (y/N): \033[0m' confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "\033[1;34m[Cleanup] Removing orphaned container: $container\033[0m"
                if docker rm -f "$container" 2>/dev/null; then
                    echo -e "\033[1;32m[Cleanup] ✓ Container removed\033[0m"
                else
                    echo -e "\033[1;33m[Cleanup] Warning: Could not remove container\033[0m"
                fi
                
                # Also try to remove the associated image
                local image_name="projects-laravel_${container}"
                if docker images | grep -q "$image_name"; then
                    read -p $'\033[1;31mRemove associated image? (y/N): \033[0m' confirm_image
                    if [[ "$confirm_image" =~ ^[Yy]$ ]]; then
                        echo -e "\033[1;34m[Cleanup] Removing orphaned image: $image_name\033[0m"
                        if docker rmi "$image_name" 2>/dev/null; then
                            echo -e "\033[1;32m[Cleanup] ✓ Image removed\033[0m"
                        else
                            echo -e "\033[1;33m[Cleanup] Warning: Could not remove image\033[0m"
                        fi
                    fi
                fi
            else
                echo -e "\033[1;33m[Cleanup] Skipped container: $container\033[0m"
            fi
        else
            echo -e "\033[1;32m[Cleanup] Container $container is still in use by: $still_used\033[0m"
        fi
    done
    
    if [[ "$found_orphans" == "false" ]]; then
        echo -e "\033[1;32m[Cleanup] No orphaned containers found.\033[0m"
    fi
    
    echo -e "\033[1;32m[Cleanup] ✓ Cleanup completed\033[0m"
}

# Run the cleanup if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cleanup_orphaned_containers
fi 