#!/bin/bash

CONFIG_FILE="config.json"
COMPOSE_FILE="docker-compose.yml"
MYSQL_CONTAINER_NAME=$(jq -r '.docker_settings.mysql.container_name' "$CONFIG_FILE")

generate_compose_file() {
    echo -e "\n\033[1;33mGenerating docker-compose.yml...\033[0m"

    # start write to the docker-compose file
    cat > "$COMPOSE_FILE" <<EOF
version: '3.8'

services:
  mysql:
    build:
      context: ./docker/mysql
      dockerfile: Dockerfile
    container_name: $MYSQL_CONTAINER_NAME
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
      - ./docker/mysql/init.sh:/init.sh
      - ./docker/mysql/database_config.json:/database_config.json
    networks:
      - \${BACKEND_NETWORK}
EOF

    cat >> "$COMPOSE_FILE" <<EOF    

  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    container_name: phpmyadmin
    restart: always
    ports:
      - "8081:80"  
    environment:
      PMA_HOST: $MYSQL_CONTAINER_NAME
      PMA_PORT: 3306
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
    depends_on:
      - mysql
    networks:
      - \${BACKEND_NETWORK}
EOF

    # Group sites by PHP version
    declare -A php_versions
    declare -A php_sites
    
    # Extract all unique PHP versions and their sites
    while IFS= read -r php_version; do
        if [[ -n "$php_version" ]]; then
            php_versions["$php_version"]=1
            # Get all sites for this PHP version
            sites_for_version=$(jq -r --arg version "$php_version" '.docker_settings.sites[] | select(.php_version == $version) | .name' "$CONFIG_FILE")
            php_sites["$php_version"]="$sites_for_version"
        fi
    done < <(jq -r '.docker_settings.sites[].php_version' "$CONFIG_FILE" | sort -u)

    # Create one container per PHP version
    for php_version in "${!php_versions[@]}"; do
        # Create container name based on PHP version
        container_name="php-${php_version//./}"
        
        cat >> "$COMPOSE_FILE" <<EOF

  $container_name:
    build:
      context: .
      dockerfile: ./docker/php/Dockerfile
      args:
        - PHP_VERSION=$php_version
        - APP_NAME=multi
    container_name: $container_name
    environment:
      APP_NAME: multi
      DB_HOST: mysql
EOF

        # Add environment variables for all sites in this PHP version
        while IFS= read -r site_name; do
            if [[ -n "$site_name" ]]; then
                VAR_PREFIX=$(echo "$site_name" | tr '[:lower:]-' '[:upper:]_')
                cat >> "$COMPOSE_FILE" <<EOF
      ${VAR_PREFIX}_DB_NAME: \${${VAR_PREFIX}_DB_NAME}
      ${VAR_PREFIX}_DB_USER: \${${VAR_PREFIX}_DB_USER}
      ${VAR_PREFIX}_DB_PASSWORD: \${${VAR_PREFIX}_DB_PASSWORD}
EOF
            fi
        done <<< "${php_sites[$php_version]}"

        cat >> "$COMPOSE_FILE" <<EOF
    depends_on:
      - mysql
    volumes:
EOF

        # Mount all sites for this PHP version
        while IFS= read -r site_name; do
            if [[ -n "$site_name" ]]; then
                cat >> "$COMPOSE_FILE" <<EOF
      - ./sites/$site_name:/var/www/html/$site_name
EOF
            fi
        done <<< "${php_sites[$php_version]}"

        cat >> "$COMPOSE_FILE" <<EOF
    networks:
      - \${BACKEND_NETWORK}
      - \${FRONTEND_NETWORK}
EOF
    done

    # nginx service
    cat >> "$COMPOSE_FILE" <<EOF

  nginx:
    image: nginx:latest
    container_name: nginx-proxy
    restart: always
    volumes:
      - ./docker/nginx/conf.d:/etc/nginx/conf.d
EOF

    # mounting all sites to the nginx container
    jq -r '.docker_settings.sites[].root' "$CONFIG_FILE" | while read -r root; do
        echo "      - ./sites/$root:/var/www/html/$root" >> "$COMPOSE_FILE"
    done

    cat >> "$COMPOSE_FILE" <<EOF
    ports:
      - "\${NGINX_HTTP_PORT}:80"
    depends_on:
EOF

    # nginx depends on all PHP containers
    for php_version in "${!php_versions[@]}"; do
        container_name="php-${php_version//./}"
        echo "      - $container_name" >> "$COMPOSE_FILE"
    done

    cat >> "$COMPOSE_FILE" <<EOF
    networks:
      - \${FRONTEND_NETWORK}

volumes:
  mysql_data:

networks:
  backend:
  frontend:
EOF

    echo -e "\n\033[1;32mdocker-compose.yml successfully generated!\033[0m"
}

# Execute function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_compose_file "$@"
fi
