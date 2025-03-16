#!/bin/bash

# 1. Get the website name from the user
# 1. Получаем имя сайта от пользователя
echo "Enter the new site name (e.g., site4):"
read site_name

# 2. Get the database name (default: site_name_db)
# 2. Получаем имя базы данных (по умолчанию: site_name_db)
echo "Enter the database name (default: ${site_name}_db):"
read db_name
db_name=${db_name:-"${site_name}_db"}

# 3. Create the site directory and install Laravel
# 3. Создаём папку с Laravel-проектом и устанавливаем Laravel
mkdir -p "./sites/$site_name"
docker run --rm -v "$(pwd)/sites/$site_name":/app composer create-project --prefer-dist laravel/laravel /app

echo "Laravel installed in ./sites/$site_name"

# 4. Add new service to docker-compose.yml
# 4. Добавляем новый сервис в docker-compose.yml
awk -v site="$site_name" -v db="$db_name" '
/^services:/ {print; print "  " site ":"; next}
$0 ~ /^  mysql:/ { 
  print "    environment:"; 
  print "      - MYSQL_DATABASE=" db; 
} 
{print}
' docker-compose.yml > temp.yml && mv temp.yml docker-compose.yml

echo "Added service $site_name to docker-compose.yml"

# 5. Create Nginx configuration
# 5. Создаём конфиг Nginx
cat <<EOL > nginx/conf.d/$site_name.conf
server {
    listen 80;
    server_name $site_name.local;

    root /var/www/html/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass $site_name:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOL

echo "Created Nginx config: nginx/conf.d/$site_name.conf"

# 6. Create MySQL database
# 6. Создаём базу данных в MySQL
docker exec -i mysql mysql -uroot -psecret -e "CREATE DATABASE $db_name;"
echo "Database $db_name created successfully."

# 7. Start the new container without restarting others
# 7. Запускаем новый контейнер без остановки других
docker compose up -d $site_name

# 8. Restart only Nginx
# 8. Перезапускаем только Nginx
docker compose restart nginx

echo "Site $site_name has been added successfully!"

# 9. Add the site to Cloudflare Tunnel config
# 9. Добавляем сайт в Cloudflare Tunnel config
cloudflare_config="cloudflared/config.yml"
tunnel_id="YOUR_TUNNEL_ID"

echo "
  - hostname: $site_name.yourdomain.com
    service: http://localhost:80" >> $cloudflare_config

echo "Added $site_name to Cloudflare Tunnel config."
