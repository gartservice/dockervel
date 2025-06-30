#!/bin/bash

CONFIG_FILE="./config.json"
NGINX_CONF_DIR="./docker/nginx/conf.d"

generate_nginx_confs() {
    echo -e "\n\033[1;33mGenerating nginx config files with per-site SSL support...\033[0m"

    mkdir -p "$NGINX_CONF_DIR"

    jq -c '.docker_settings.sites[]' "$CONFIG_FILE" | while read -r site; do
        NAME=$(echo "$site" | jq -r '.name')
        SERVER_NAME=$(echo "$site" | jq -r '.server_name')
        ROOT=$(echo "$site" | jq -r '.root')
        PUBLIC_FOLDER=$(echo "$site" | jq -r '.public_folder // "public"')
        SSL_ENABLED=$(echo "$site" | jq -r '.ssl.enabled // false')
        SSL_CERT=$(echo "$site" | jq -r '.ssl.cert // empty')
        SSL_KEY=$(echo "$site" | jq -r '.ssl.key // empty')

        CONF_FILE="$NGINX_CONF_DIR/$NAME.conf"

        echo "# Config for $NAME" > "$CONF_FILE"

        # Redirect HTTP to HTTPS if SSL is enabled
        if [[ "$SSL_ENABLED" == "true" ]]; then
            cat >> "$CONF_FILE" <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    return 301 https://\$host\$request_uri;
}
EOF
            echo "" >> "$CONF_FILE"
        fi

        # Main server block
        echo "server {" >> "$CONF_FILE"

        if [[ "$SSL_ENABLED" == "true" ]]; then
            echo "    listen 443 ssl http2;" >> "$CONF_FILE"
            echo "    ssl_certificate     $SSL_CERT;" >> "$CONF_FILE"
            echo "    ssl_certificate_key $SSL_KEY;" >> "$CONF_FILE"
        else
            echo "    listen 80;" >> "$CONF_FILE"
        fi

        cat >> "$CONF_FILE" <<EOF
    server_name $SERVER_NAME;

    root /var/www/html/$ROOT/$PUBLIC_FOLDER;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location /storage/ {
        alias /var/www/html/$ROOT/storage/app/public/;

        access_log off;
        expires max;
    }


    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass $NAME:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param SERVER_NAME \$host;
    }

    access_log /var/log/nginx/${NAME}.access.log;
    error_log /var/log/nginx/${NAME}.error.log;
}
EOF

        echo -e "\033[1;32mGenerated: $CONF_FILE\033[0m"
    done
}


