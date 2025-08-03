#!/bin/bash

CONFIG_FILE="./config.json"

# Function to get all sites from config.json
get_all_sites() {
    jq -r '.docker_settings.sites[].name' "$CONFIG_FILE" 2>/dev/null
}

# Function to get site details from config.json
get_site_details() {
    local site_name=$1
    jq -r --arg name "$site_name" '.docker_settings.sites[] | select(.name == $name)' "$CONFIG_FILE" 2>/dev/null
}

# Function to delete database
delete_database() {
    local site_name=$1
    local site_details=$(get_site_details "$site_name")
    
    if [[ -z "$site_details" ]]; then
        echo -e "\033[1;31mError: Site '$site_name' not found in config.json\033[0m"
        return 1
    fi
    
    local db_name=$(echo "$site_details" | jq -r '.db_name')
    local db_user=$(echo "$site_details" | jq -r '.db_user')
    local db_password=$(echo "$site_details" | jq -r '.db_password')
    
    if [[ -z "$db_name" || "$db_name" == "null" ]]; then
        echo -e "\033[1;33m[${site_name}] No database name found for site '$site_name'\033[0m"
        return 0
    fi
    
    echo -e "\033[1;36m[${site_name}] Checking if database '$db_name' exists...\033[0m"
    
    # Check if MySQL container is running
    if ! docker-compose ps -q mysql | grep -q .; then
        echo -e "\033[1;31m[${site_name}] Error: MySQL container is not running. Cannot delete database.\033[0m"
        return 1
    fi
    
    # Check if database exists
    if docker exec mysql mysql -u"$db_user" -p"$db_password" -e "USE \`$db_name\`;" 2>/dev/null; then
        echo -e "\033[1;31m[${site_name}] Database '$db_name' exists and contains data!\033[0m"
        echo -e "\033[1;31m[${site_name}] This will permanently delete ALL data in the database!\033[0m"
        
        read -p $'\n\033[1;31mAre you sure you want to delete the database? (yes/no): \033[0m' db_confirmation
        
        if [[ "$db_confirmation" == "yes" ]]; then
            echo -e "\033[1;36m[${site_name}] Deleting database '$db_name'...\033[0m"
            if docker exec mysql mysql -u"$db_user" -p"$db_password" -e "DROP DATABASE \`$db_name\`;" 2>/dev/null; then
                echo -e "\033[1;32m[${site_name}] ✓ Database '$db_name' deleted successfully\033[0m"
                return 0
            else
                echo -e "\033[1;31m[${site_name}] ✗ Error: Failed to delete database '$db_name'\033[0m"
                return 1
            fi
        else
            echo -e "\033[1;33m[${site_name}] Database deletion cancelled. Database '$db_name' will remain.\033[0m"
            return 0
        fi
    else
        echo -e "\033[1;33m[${site_name}] Database '$db_name' does not exist or is not accessible\033[0m"
        return 0
    fi
}

# Function to show database deletion menu
show_database_deletion_menu() {
    clear
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m       Delete Database Menu         \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    # Get all sites
    local db_sites=$(get_all_sites)
    
    if [[ -z "$db_sites" ]]; then
        echo -e "\n\033[1;33mNo sites found in config.json\033[0m"
        read -p "Press Enter to return to the main menu..."
        return
    fi
    
    # Show sites with fzf, including back option
    local db_selected_site=$(printf "Back to Main Menu\n%s" "$db_sites" | fzf --height=15 --reverse --border --prompt "Select site to delete database: ")
    
    if [[ -z "$db_selected_site" ]]; then
        echo -e "\n\033[1;33mNo selection made. Returning to main menu.\033[0m"
        read -p "Press Enter to continue..."
        return
    fi
    
    if [[ "$db_selected_site" == "Back to Main Menu" ]]; then
        echo -e "\n\033[1;34mReturning to main menu...\033[0m"
        return
    fi
    
    # Show site details before deletion
    local site_details=$(get_site_details "$db_selected_site")
    if [[ -n "$site_details" ]]; then
        echo -e "\n\033[1;36m=== Site Details ===\033[0m"
        echo -e "Name: $(echo "$site_details" | jq -r '.name')"
        echo -e "Database: $(echo "$site_details" | jq -r '.db_name')"
        echo -e "Database User: $(echo "$site_details" | jq -r '.db_user')"
        echo -e "\033[1;36m==================\033[0m"
    fi
    
    # Delete the database for the selected site
    delete_database "$db_selected_site"
    
    read -p "Press Enter to return to the main menu..."
}

# Function to delete database for a specific site (for direct script calls)
delete_database_direct() {
    local site_name=$1
    
    if [[ -z "$site_name" ]]; then
        echo -e "\033[1;31mError: Please provide a site name\033[0m"
        echo -e "Usage: $0 <site_name>"
        echo -e "   or: $0 (for interactive menu)"
        exit 1
    fi
    
    delete_database "$site_name"
}

# Run the menu if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 1 ]]; then
        delete_database_direct "$1"
    else
        show_database_deletion_menu
    fi
fi 