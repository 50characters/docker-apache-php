FROM php:8.2-apache

RUN a2enmod rewrite

RUN set -xe \
    && apt-get update \
    && apt-get install -y libxml2-dev libfreetype-dev libjpeg62-turbo-dev libc-client-dev libkrb5-dev \
    && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install gd mysqli pdo pdo_mysql imap ftp soap
RUN  pecl install xdebug-3.2.1 
