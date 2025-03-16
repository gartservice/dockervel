# Function to add a new site
add_new_site() {
    echo -e "\n\033[1;34mAdding a new site...\033[0m"
    read -p "Enter site name: " SITE_NAME
    read -p "Enter site DNS (e.g., site.local): " SITE_DNS
    read -p "Enter database name (default: $SITE_NAME): " DB_NAME
    DB_NAME=${DB_NAME:-$SITE_NAME}
    read -p "Enter database user (default: root): " DB_USER
    DB_USER=${DB_USER:-root}
    read -p "Enter database password (default: secret): " DB_PASSWORD
    DB_PASSWORD=${DB_PASSWORD:-secret}
    
    PHP_VERSIONS=$(jq -r '.local_settings.available_php_versions[]' "$CONFIG_FILE")
    echo -e "\nAvailable PHP versions: $PHP_VERSIONS"
    read -p "Select PHP version (default: 8.4): " PHP_VERSION
    PHP_VERSION=${PHP_VERSION:-8.4}

    SITE_PATH="$SITES_FOLDER/$SITE_NAME"
    if [ ! -d "$SITE_PATH" ]; then
        mkdir -p "$SITE_PATH"
        echo -e "\n\033[1;32mCreated site folder: $SITE_PATH\033[0m"
    else
        echo -e "\n\033[1;33mSite folder already exists: $SITE_PATH\033[0m"
    fi
    
    echo -e "\nChoose installation type:\n1) Laravel\n2) WordPress\n3) Existing Project (GitHub)"
    read -p "Enter your choice: " INSTALL_TYPE
    
    if [[ "$INSTALL_TYPE" == "1" ]]; then
        LARAVEL_VERSIONS=$(jq -r '.local_settings.available_laravel_versions[]' "$CONFIG_FILE")
        echo -e "\nAvailable Laravel versions: $LARAVEL_VERSIONS"
        read -p "Select Laravel version (default: latest): " LARAVEL_VERSION
        LARAVEL_VERSION=${LARAVEL_VERSION:-latest}
        composer create-project --prefer-dist laravel/laravel="$LARAVEL_VERSION" "$SITE_PATH"
        echo -e "\n\033[1;32mLaravel $LARAVEL_VERSION installed in $SITE_PATH\033[0m"
    elif [[ "$INSTALL_TYPE" == "2" ]]; then
        wget https://wordpress.org/latest.tar.gz -P "$SITE_PATH"
        tar -xzf "$SITE_PATH/latest.tar.gz" -C "$SITE_PATH" --strip-components=1
        rm "$SITE_PATH/latest.tar.gz"
        echo -e "\n\033[1;32mWordPress installed in $SITE_PATH\033[0m"
    elif [[ "$INSTALL_TYPE" == "3" ]]; then
        read -p "Enter GitHub repository URL: " GIT_URL
        git clone "$GIT_URL" "$SITE_PATH"
        echo -e "\n\033[1;32mExisting project cloned to $SITE_PATH\033[0m"
    else
        echo -e "\n\033[1;31mInvalid selection. Site creation aborted.\033[0m"
    fi
    
    echo -e "\n\033[1;34mSite $SITE_NAME added successfully!\033[0m"
}