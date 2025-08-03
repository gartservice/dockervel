ARG PHP_VERSION=8.4

FROM php:${PHP_VERSION}-fpm

RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    git \
    libicu-dev \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    zlib1g-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        bcmath \
        ctype \
        fileinfo \
        intl \
        mbstring \
        pdo_mysql \
        xml \
        zip \
        opcache \
    && docker-php-source delete

# install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ARG APP_NAME
ENV APP_DIR=/var/www/html/${APP_NAME}
WORKDIR ${APP_DIR}

COPY ./docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ENTRYPOINT ["entrypoint.sh"]
