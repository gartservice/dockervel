#!/bin/bash

CONFIG_FILE="config.json"
COMPOSE_FILE="docker-compose.yml"

generate_compose_file() {
    echo -e "\n\033[1;33mGenerating docker-compose.yml...\033[0m"

    # start write to the docker-compose file
    cat > "$COMPOSE_FILE" <<EOF
services:
  mysql:
    build:
      context: ./docker/mysql
      dockerfile: Dockerfile
    container_name: $(jq -r '.docker_settings.mysql.container_name' "$CONFIG_FILE")
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
      - ./docker/mysql/init.sh:/init.sh
      - ./config.json:/config.json
    networks:
      - \${BACKEND_NETWORK}
  phpmyadmin:
    image: phpmyadmin/phpmyadmin:latest
    container_name: phpmyadmin
    restart: always
    ports:
      - "8081:80"  
    environment:
      PMA_HOST: mysql-server
      PMA_PORT: 3306
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    depends_on:
      - mysql
    networks:
      - \${BACKEND_NETWORK}
EOF

    # add sites to compose file
    jq -c '.docker_settings.sites[]' "$CONFIG_FILE" | while read -r site; do
        NAME=$(echo "$site" | jq -r '.name')
        ROOT=$(echo "$site" | jq -r '.root')
        PHP_VERSION=$(echo "$site" | jq -r '.php_version')
        VAR_PREFIX=$(echo "$NAME" | tr '[:lower:]-' '[:upper:]_')

        cat >> "$COMPOSE_FILE" <<EOF

  $NAME:
    build:
      context: .
      dockerfile: ./docker/php/Dockerfile
      args:
        - PHP_VERSION=$PHP_VERSION
        - APP_NAME=$NAME
    container_name: $NAME
    environment:
      APP_NAME: $NAME
      DB_HOST: mysql
      DB_DATABASE: \${${VAR_PREFIX}_DB_NAME}
      DB_USERNAME: \${${VAR_PREFIX}_DB_USER}
      DB_PASSWORD: \${${VAR_PREFIX}_DB_PASSWORD}
    depends_on:
      - mysql
    volumes:
      - ./sites/$ROOT:/var/www/html/$ROOT
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

    # mounting sites to the nginx container
    jq -r '.docker_settings.sites[].root' "$CONFIG_FILE" | while read -r root; do
        echo "      - ./sites/$root:/var/www/html/$root" >> "$COMPOSE_FILE"
    done

    cat >> "$COMPOSE_FILE" <<EOF
    ports:
      - "\${NGINX_HTTP_PORT}:80"
    depends_on:
EOF

    # nginx depends on sites
    jq -r '.docker_settings.sites[].name' "$CONFIG_FILE" | while read -r name; do
        echo "      - $name" >> "$COMPOSE_FILE"
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


