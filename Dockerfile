FROM php:8.4-apache

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libxml2-dev libfreetype6-dev libpng-dev libjpeg-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mysqli pdo pdo_mysql ftp soap
RUN  pecl install xdebug-3.5.3
