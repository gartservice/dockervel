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

# Function to validate folder names (allow letters, numbers, dashes, and underscores)
validate_folder_name() {
    if [[ ! "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "\n\033[1;31mInvalid name! Use only letters, numbers, dashes (-), or underscores (_).\033[0m"
        return 1
    fi
    return 0
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
            echo -e "\033[1;31mError: Site '$SITE_NAME' already exists. Choose a different name.\033[0m"
            continue
        fi
        if folder_exists "$SITE_NAME"; then
            echo -e "\033[1;31mError: Folder '$SITE_NAME' already exists in '$SITES_FOLDER'.\033[0m"
            continue
        fi
        break
    done
}

# Function to prompt other inputs
prompt_input() {
    local prompt_message=$1
    local var_name=$2
    local default_value=$3

    while true; do
        read -p "$prompt_message [$default_value]: " input_value
        input_value=${input_value:-$default_value}
        eval "$var_name=\"$input_value\""
        break
    done
}

add_new_site() {
    clear
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m       Add a New Site Menu         \033[0m"
    echo -e "\033[1;36m====================================\033[0m"

    prompt_site_name
    prompt_input "Enter site DNS (e.g., site.local)" SITE_DNS "${SITE_NAME}.local"
    prompt_input "Enter database name" DB_NAME "${SITE_NAME}_db"
    prompt_input "Enter database user" DB_USER "root"
    prompt_input "Enter database password" DB_PASSWORD "secret"
    prompt_input "Enter public folder (e.g. 'public' for Laravel, '.' for WordPress)" PUBLIC_FOLDER "public"

    read -p "Enable SSL for this site? (y/n) [y]: " ENABLE_SSL
    ENABLE_SSL=${ENABLE_SSL:-y}
    if [[ "$ENABLE_SSL" =~ ^[Yy]$ ]]; then
        SSL_ENABLED=true
        SSL_CERT="certs/${SITE_NAME}.crt"
        SSL_KEY="certs/${SITE_NAME}.key"

        mkdir -p certs
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_KEY" \
            -out "$SSL_CERT" \
            -subj "/CN=$SITE_DNS"
    else
        SSL_ENABLED=false
        SSL_CERT=""
        SSL_KEY=""
    fi

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

    ./bash-scripts/add_site_to_config_file.sh \
        "$SITE_NAME" "$SITE_PATH" "$SITE_DNS" "$DB_NAME" "$DB_USER" "$DB_PASSWORD" "$PHP_VERSION" \
        "$PUBLIC_FOLDER" "$SSL_ENABLED" "$SSL_CERT" "$SSL_KEY"

    INSTALL_TYPE=$(printf "Laravel\nWordPress\nExisting Project (GitHub)" | fzf --height=10 --reverse --border --prompt "Choose installation type: ")

    case "$INSTALL_TYPE" in
        "Laravel")
            LARAVEL_VERSION=$(jq -r '.local_settings.available_laravel_versions[]' "$CONFIG_FILE" | fzf --height=10 --reverse --border --prompt "Select Laravel version: ")
            composer create-project --prefer-dist laravel/laravel="$LARAVEL_VERSION" "$SITE_PATH"
            echo -e "\n\033[1;32mLaravel $LARAVEL_VERSION installed in $SITE_PATH\033[0m"

            cd "$SITE_PATH"
            cp .env.example .env
            php artisan key:generate
            cd - >/dev/null
            # Update .env to use MySQL settings
            echo -e "\033[1;34m[Auto] Updating .env file with MySQL settings...\033[0m"
            ./bash-scripts/set_laravel_env_mysql.sh "$SITE_NAME"
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

            if [[ -f "$SITE_PATH/composer.json" ]]; then
                cd "$SITE_PATH"
                composer install
                echo -e "\033[1;34mComposer dependencies installed.\033[0m"

                if [[ -f artisan && -f .env.example ]]; then
                    cp .env.example .env
                    php artisan key:generate
                    echo -e "\033[1;34mLaravel app key generated.\033[0m"
                    cd - >/dev/null
                    # Update .env to use MySQL settings for Laravel projects
                    echo -e "\033[1;34m[Auto] Updating .env file with MySQL settings...\033[0m"
                    ./bash-scripts/set_laravel_env_mysql.sh "$SITE_NAME"
                elif [[ -f artisan ]]; then
                    # Laravel project without .env.example, check if .env exists
                    if [[ ! -f .env ]]; then
                        echo -e "\033[1;34mCreating .env file for Laravel project...\033[0m"
                        # Create a basic .env file with Laravel defaults
                        cat > .env << 'EOF'
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=mt1

VITE_APP_NAME="${APP_NAME}"
VITE_PUSHER_APP_KEY="${PUSHER_APP_KEY}"
VITE_PUSHER_HOST="${PUSHER_HOST}"
VITE_PUSHER_PORT="${PUSHER_PORT}"
VITE_PUSHER_SCHEME="${PUSHER_SCHEME}"
VITE_PUSHER_APP_CLUSTER="${PUSHER_APP_CLUSTER}"
EOF
                    fi
                    php artisan key:generate
                    echo -e "\033[1;34mLaravel app key generated.\033[0m"
                    cd - >/dev/null
                    # Update .env to use MySQL settings for Laravel projects
                    echo -e "\033[1;34m[Auto] Updating .env file with MySQL settings...\033[0m"
                    ./bash-scripts/set_laravel_env_mysql.sh "$SITE_NAME"
                else
                    cd - >/dev/null
                fi
            fi
            ;;
        *)
            echo -e "\n\033[1;31mInvalid selection. Site creation aborted.\033[0m"
            ;;
    esac

    echo -e "\n\033[1;34mSite $SITE_NAME added successfully!\033[0m"

    # --- AUTOMATION STARTS HERE ---    
    echo -e "\033[1;36m[Auto] Generating .env file...\033[0m"
    ./bash-scripts/generate_env.sh --force
    echo -e "\033[1;36m[Auto] Generating docker-compose.yml...\033[0m"
    ./bash-scripts/generate_docker_compose.sh
    echo -e "\033[1;36m[Auto] Generating nginx config files...\033[0m"
    ./bash-scripts/generate_nginx_confs.sh
    echo -e "\033[1;36m[Auto] Generating database config...\033[0m"
    ./bash-scripts/generate_database_config.sh --force
    echo -e "\033[1;36m[Auto] Checking PHP container for version $PHP_VERSION...\033[0m"
    # Get the PHP version for this site and check if container exists
    PHP_CONTAINER="php-${PHP_VERSION//./}"
    
    # Save container name for future use
    echo -e "\033[1;34m[Auto] PHP container name: $PHP_CONTAINER\033[0m"
    echo -e "\033[1;34m[Auto] Project path inside container: /var/www/html/$SITE_NAME\033[0m"
    
    # Check if the container already exists
    if docker-compose ps -q $PHP_CONTAINER | grep -q .; then
        echo -e "\033[1;33m[Auto] PHP container $PHP_CONTAINER already exists. Recreating to pick up new site...\033[0m"
        # Recreate the container to pick up the new site volume mount
        docker-compose down --remove-orphans
        docker-compose up -d
    else
        echo -e "\033[1;36m[Auto] Building new PHP container: $PHP_CONTAINER\033[0m"
        docker-compose build $PHP_CONTAINER
        docker-compose up -d $PHP_CONTAINER
    fi
    
    # Wait a moment for container to fully start
    echo -e "\033[1;34m[Auto] Waiting for container to start...\033[0m"
    sleep 5
    
    # Verify the site is mounted in the container
    if docker exec $PHP_CONTAINER test -d "/var/www/html/$SITE_NAME"; then
        echo -e "\033[1;32m[Auto] ✓ Site folder mounted successfully in container\033[0m"
    else
        echo -e "\033[1;31m[Auto] ✗ Error: Site folder not found in container. Trying to restart container again...\033[0m"
        docker-compose restart $PHP_CONTAINER
        sleep 3
        if docker exec $PHP_CONTAINER test -d "/var/www/html/$SITE_NAME"; then
            echo -e "\033[1;32m[Auto] ✓ Site folder now mounted after restart\033[0m"
        else
            echo -e "\033[1;31m[Auto] ✗ Error: Site folder still not mounted. Please check manually.\033[0m"
        fi
    fi
    
    echo -e "\033[1;36m[Auto] Nginx container will be recreated with new configs...\033[0m"
    
    echo -e "\033[1;36m[Auto] Initializing database for new site...\033[0m"
    source ./bash-scripts/initialize_database.sh
    initialize_database
    echo -e "\033[1;32m[Auto] Database initialization complete.\033[0m"
    
    # Run database migrations for Laravel projects
    if [[ "$INSTALL_TYPE" == "Laravel" ]] || ([[ "$INSTALL_TYPE" == "Existing Project (GitHub)" ]] && docker exec $PHP_CONTAINER test -f "/var/www/html/$SITE_NAME/artisan"); then
        echo -e "\033[1;36m[Auto] Running database migrations for Laravel project...\033[0m"
        if docker exec $PHP_CONTAINER php "/var/www/html/$SITE_NAME/artisan" migrate --force; then
            echo -e "\033[1;32m[Auto] ✓ Database migrations completed successfully\033[0m"
        else
            echo -e "\033[1;33m[Auto] Warning: Database migrations failed. You may need to run them manually.\033[0m"
            echo -e "\033[1;33m[Auto] Manual command: docker exec $PHP_CONTAINER php /var/www/html/$SITE_NAME/artisan migrate\033[0m"
        fi
    fi
    
    echo -e "\033[1;32m[Auto] Done! New site is live (if no errors above).\033[0m"
    read -p "Press Enter to return to the main menu..."
}
