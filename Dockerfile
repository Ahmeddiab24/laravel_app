FROM composer:2.7 AS composer-builder

WORKDIR /app

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --ignore-platform-reqs

COPY . .

RUN composer dump-autoload --optimize --no-dev

FROM node:20-alpine AS node-builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci 

COPY . .

RUN npm run build



FROM php:8.3-fpm-alpine AS production

RUN apk add --no-cache \
        bash \
        curl \
        shadow \
        supervisor \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        libzip-dev \
        oniguruma-dev \
        icu-dev \
        postgresql-dev \
        mysql-client \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        mysqli \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        intl \
        opcache \
    && apk del --no-cache \
        libpng-dev libjpeg-turbo-dev freetype-dev \
        libzip-dev oniguruma-dev icu-dev postgresql-dev \
    && rm -rf /var/cache/apk/* /tmp/*
COPY Docker/php/Opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY Docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini

RUN sed -i 's|listen = /var/run/php/.*|listen = 0.0.0.0:9000|' \
        /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's|;listen.owner.*|listen.owner = laravel|' \
        /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's|;listen.group.*|listen.group = laravel|' \
        /usr/local/etc/php-fpm.d/www.conf

COPY Docker/php/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN addgroup -g 1000 laravel \
    && adduser -u 1000 -G laravel -s /bin/bash -D laravel \
    && mkdir -p /var/log/supervisor \
    && chown laravel:laravel /var/log/supervisor

WORKDIR /var/www/html

COPY --chown=laravel:laravel . .
COPY --chown=laravel:laravel --from=composer-builder /app/vendor        ./vendor
COPY --chown=laravel:laravel --from=node-builder     /app/public/build  ./public/build

RUN chown -R laravel:laravel /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

COPY Docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER laravel

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]