FROM php:5.6.40-apache

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libxml2-dev libpng-dev libjpeg-dev libc-client-dev libkrb5-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install gd mysql mysqli pdo pdo_mysql imap ftp soap