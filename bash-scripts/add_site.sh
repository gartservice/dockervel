#!/bin/bash

CONFIG_FILE="./config.json"
SITES_FOLDER=$(jq -r '.local_settings.sites_folder' "$CONFIG_FILE")


# Function to check if the site already exists in config.json
site_exists() {
    jq -e --arg name "$1" '.docker_settings.sites[] | select(.name == $name)' "$CONFIG_FILE" >/dev/null
}

# Function to check if the folder already exists
folder_exists() {
    [[ -d "$SITES_FOLDER/$1" ]]
}
# Function to ensure required input and check for duplicate site names
prompt_site_name() {
    while true; do
        read -p "Enter site name: " SITE_NAME
        if [[ -z "$SITE_NAME" ]]; then
            echo -e "\033[1;31mSite name cannot be empty!\033[0m"
            continue
        fi
        if ! validate_folder_name "$SITE_NAME"; then
            continue
        fi
        if site_exists "$SITE_NAME"; then
            echo -e "\033[1;31mError: A site with the name '$SITE_NAME' already exists. Please choose a different name.\033[0m"

            continue
        fi
        if folder_exists "$SITE_NAME"; then
            echo -e "\033[1;31mError: A folder with the name '$SITE_NAME' already exists in '$SITES_FOLDER'. Please choose a different name.\033[0m"
            continue
        fi
        break
    done
}
 


# Function to validate folder names (allow letters, numbers, dashes, and underscores)
validate_folder_name() {
    if [[ ! "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "\n\033[1;31mInvalid name! Use only letters, numbers, dashes (-), or underscores (_).\033[0m"
        return 1
    fi
    return 0
}

# Function to prompt other inputs
prompt_input() {
    local prompt_message=$1
    local var_name=$2
    local default_value=$3

    while true; do
        read -p "$prompt_message [$default_value]: " input_value
        input_value=${input_value:-$default_value}
        eval "$var_name='$input_value'"
        break
    done
}

# Function to add a new site via an interactive menu
add_new_site() {
    while true; do
        clear
        echo -e "\n\033[1;36m====================================\033[0m"
        echo -e "\033[1;36m       Add a New Site Menu         \033[0m"
        echo -e "\033[1;36m====================================\033[0m"
        echo -e "\n\033[1;33mUse arrow keys to navigate and Enter to select:\033[0m"

        # Ensure unique site name
        prompt_site_name
        prompt_input "Enter site DNS (e.g., site.local)" SITE_DNS "${SITE_NAME}.local"
        prompt_input "Enter database name" DB_NAME "${SITE_NAME}_db"
        prompt_input "Enter database user" DB_USER "root"
        prompt_input "Enter database password" DB_PASSWORD "secret"

        # Select PHP version using jq and fzf
        PHP_VERSION=$(jq -r '.local_settings.available_php_versions[]' "$CONFIG_FILE" | fzf --height=10 --reverse --border --prompt "Select PHP version: ")

        # Define site path
        SITE_PATH="$SITES_FOLDER/$SITE_NAME"
        echo "SITE_PATH: '$SITE_PATH'"

        # Ensure site path exists
        if [ ! -d "$SITE_PATH" ]; then
            mkdir -p "$SITE_PATH" && echo -e "\n\033[1;32mSuccessfully created site folder: $SITE_PATH\033[0m" || { 
                echo -e "\033[1;31mError creating directory. Check permissions.\033[0m"; 
                exit 1; 
            }
        else
            echo -e "\n\033[1;33mSite folder already exists: $SITE_PATH\033[0m"
        fi

        # Call external script to update config.json
        ./bash-scripts/add_site_to_config_file.sh "$SITE_NAME" "$SITE_PATH" "$SITE_DNS" "$DB_NAME" "$DB_USER" "$DB_PASSWORD" "$PHP_VERSION"

        # Select installation type using fzf
        INSTALL_TYPE=$(printf "Laravel\nWordPress\nExisting Project (GitHub)" | fzf --height=10 --reverse --border --prompt "Choose installation type: ")

        case "$INSTALL_TYPE" in
            "Laravel")
                LARAVEL_VERSION=$(jq -r '.local_settings.available_laravel_versions[]' "$CONFIG_FILE" | fzf --height=10 --reverse --border --prompt "Select Laravel version: ")
                composer create-project --prefer-dist laravel/laravel="$LARAVEL_VERSION" "$SITE_PATH"
                echo -e "\n\033[1;32mLaravel $LARAVEL_VERSION installed in $SITE_PATH\033[0m"
                ;;
            "WordPress")
                wget https://wordpress.org/latest.tar.gz -P "$SITE_PATH"
                tar -xzf "$SITE_PATH/latest.tar.gz" -C "$SITE_PATH" --strip-components=1
                rm "$SITE_PATH/latest.tar.gz"
                echo -e "\n\033[1;32mWordPress installed in $SITE_PATH\033[0m"
                ;;
            "Existing Project (GitHub)")
                prompt_input "Enter GitHub repository URL" GIT_URL ""
                git clone "$GIT_URL" "$SITE_PATH"
                echo -e "\n\033[1;32mExisting project cloned to $SITE_PATH\033[0m"
                ;;
            *)
                echo -e "\n\033[1;31mInvalid selection. Site creation aborted.\033[0m"
                ;;
        esac

        echo -e "\n\033[1;34mSite $SITE_NAME added successfully!\033[0m"
        read -p "Press Enter to return to the main menu..."
        return
    done
}
