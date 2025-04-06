ARG PHP_VERSION=8.4

FROM php:${PHP_VERSION}-fpm

RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    && docker-php-ext-install pdo_mysql

ARG APP_NAME
ENV APP_DIR=/var/www/html/${APP_NAME}
WORKDIR ${APP_DIR}

COPY ./docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ENTRYPOINT ["entrypoint.sh"]
