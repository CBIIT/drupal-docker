FROM drupal:9.3.2-php8.0-fpm-alpine3.14
ENV DRUPAL_VERSION=9.3.2
ENV PHP_VERSION=8.1
RUN sh
RUN chmod 1777 /tmp
RUN chmod -R 1777 /var/tmp
RUN rm -rf /var/lib/apt/lists/*

# update sources list
RUN apk update
RUN apk add --no-cache ca-certificates wget && update-ca-certificates

# install basic apps, one per line for better caching
RUN apk --no-cache add bash \
    curl \
    git \
    mariadb-client \
    openssh \
    nano \
    sudo \
    tmux \
    php${PHP_VERSION}-apache2 \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-pdo_mysql \
    php${PHP_VERSION}-session \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-tokenizer \
    php${PHP_VERSION}-xml \
    apache2-utils
          
COPY ./resources/httpd.conf /etc/apache2/httpd.conf
COPY ./resources/run.sh /usr/bin
COPY ./resources/000-default.conf /etc/apache2/conf.d

COPY ./resources/.htaccess /opt/drupal
RUN chmod 700 /usr/bin/run.sh
WORKDIR /opt/drupal
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/bin --filename=composer
RUN composer require drush/drush:^10 --prefer-dist
WORKDIR /opt/drupal/web

ENTRYPOINT run.sh


