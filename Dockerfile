ARG PHP_VERSION=8.2
ARG DEBIAN_VERSION=bookworm

FROM php:${PHP_VERSION}-apache-${DEBIAN_VERSION} AS base

RUN set -xe \
    && a2enmod rewrite \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libxml2-dev libfreetype6-dev libpng-dev libjpeg-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli pdo pdo_mysql ftp soap

FROM base AS debug

ARG XDEBUG_VERSION=3.5.3

RUN pecl install xdebug-${XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug \
    && rm -rf /tmp/pear

COPY docker/xdebug.ini /usr/local/etc/php/conf.d/99-xdebug-settings.ini

FROM base AS runtime
