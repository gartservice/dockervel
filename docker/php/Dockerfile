ARG PHP_VERSION=8.4

FROM php:${PHP_VERSION}-fpm

RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    && docker-php-ext-install pdo_mysql
ARG APP_NAME
ENV APP_DIR=/var/www/html/${APP_NAME}
WORKDIR ${APP_DIR}

COPY ./docker/php/entrypoint.sh ${APP_DIR}/entrypoint.sh

# RUN chmod +x ${APP_DIR}/entrypoint.sh

# ENTRYPOINT ["bash", "-c", "${APP_DIR}/entrypoint.sh"]
# COPY . .
# RUN chmod -R 777 storage bootstrap/cache

# CMD ["bash", "-c", "php artisan migrate --force && php-fpm"]
# CMD ["php-fpm"]
# CMD ["php", "artisan", "migrate"]