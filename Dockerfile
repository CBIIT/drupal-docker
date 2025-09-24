FROM drupal:php8.3-fpm-alpine3.22

# Environment setup
ENV PHP_VERSION=83
ENV PHP_INI_DIR=/etc/php83

# Update repositories to edge so we can pull php83=8.3.25
RUN set -eux; \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories; \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
    apk update

# Core utilities
RUN apk add --no-cache \
    bash \
    cronie \
    curl \
    git \
    mariadb-client \
    nano \
    openssh \
    patch \
    sudo \
    tmux \
    ldb \
    openldap-clients \
    openldap \
    openldap-back-mdb \
    apache2-utils

# PHP 8.3.25 + extensions (pin exact version to 8.3.25-r0)
RUN set -eux; apk add --no-cache \
    php83=8.3.25-r0 \
    php83-fpm=8.3.25-r0 \
    php83-opcache=8.3.25-r0 \
    php83-mysqli=8.3.25-r0 \
    php83-pdo_mysql=8.3.25-r0 \
    php83-ldap=8.3.25-r0 \
    php83-gd=8.3.25-r0 \
    php83-xml=8.3.25-r0 \
    php83-dom=8.3.25-r0 \
    php83-simplexml=8.3.25-r0 \
    php83-tokenizer=8.3.25-r0 \
    php83-session=8.3.25-r0

# Point Drupal base image paths to Alpine’s PHP 8.3.25
RUN set -eux; \
    mkdir -p /usr/local/etc; \
    ln -sf /etc/php83 /usr/local/etc/php; \
    ln -sf /usr/bin/php83      /usr/local/bin/php; \
    ln -sf /usr/sbin/php-fpm83 /usr/local/sbin/php-fpm; \
    php -v && php-fpm -v

# Enable LDAP extension (optional toggle)
ARG DOCKER_PHP_ENABLE_LDAP
RUN if [ "${DOCKER_PHP_ENABLE_LDAP}" != "off" ]; then \
      apk add --no-cache libldap openldap-dev && \
      docker-php-ext-configure ldap && \
      docker-php-ext-install ldap && \
      apk del openldap-dev && \
      php -m | grep ldap; \
    else \
      echo "Skip ldap support"; \
    fi

# Permissions
RUN chmod 1777 /tmp && chmod -R 1777 /var/tmp

# Apache / Drupal configs
COPY ./resources/httpd.conf /etc/apache2/httpd.conf
COPY ./resources/run.sh /usr/bin
COPY ./resources/000-default.conf /etc/apache2/conf.d
COPY ./resources/.htaccess /tmp

WORKDIR /var/www/html

# Default command from drupal base is already php-fpm
