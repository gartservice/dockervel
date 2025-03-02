ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm

RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    && docker-php-ext-install pdo_mysql

WORKDIR /var/www/html
COPY . .
RUN chmod -R 777 storage bootstrap/cache

CMD ["php-fpm"]