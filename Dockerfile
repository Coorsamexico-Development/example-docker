#PHP
FROM php:8.1.4-fpm-alpine AS digital_dealer_php

ARG APP_ENV
ENV APP_HOME /var/www/html
ARG UID=1000
ARG GID=1000
ENV USERNAME=root

ENV TZ=UTC

WORKDIR $APP_HOME

RUN apk add --update bash zip unzip curl sqlite supervisor npm

RUN npm install -g npm
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk --no-cache add shadow && usermod -u 1000 www-data

RUN docker-php-ext-install mysqli pdo pdo_mysql

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Add user for laravel application
#RUN addgroup -g ${GID} ${USERNAME}
#RUN adduser -D -s /bin/bash -G ${USERNAME} -u 1337 ${USERNAME}
#RUN usermod -a -G ${USERNAME} nginx


# Copy existing application directory contents
COPY . $APP_HOME
COPY --chown=${USERNAME}:${USERNAME} . $APP_HOME




#Copy supervisor to manage nginx and php processes
#COPY ./docker/php-fpm/supervisord.conf /etc/
#Nginx config
RUN apk add --no-cache nginx wget

RUN mkdir -p /run/nginx

COPY docker/nginx.conf /etc/nginx/nginx.conf
#PHP ini config
#COPY ./docker/php-fpm/php.ini /usr/local/etc/php/php.ini

# Docker entrypoint script
COPY docker/startup.sh /usr/local/bin/startup
RUN chmod +x /usr/local/bin/startup
RUN chmod +x /usr/local/bin/startup

#USER sail

EXPOSE 80
ENTRYPOINT ["startup"]

#Prod
FROM digital_dealer_php AS digital_dealer_php_prod
RUN composer install --ignore-platform-reqs --optimize-autoloader --no-dev
RUN echo "building Prod with composer and npm"
#COPY --chown=${USERNAME}:${USERNAME} .env.production $APP_HOME/.env

# RUN chown -R root /var/www/html
RUN chown -R www-data: /var/www/html
RUN php artisan optimize:clear
RUN php artisan storage:link
RUN npm ci
RUN npm run build
