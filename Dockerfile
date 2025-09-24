FROM drupal:php8.3-fpm-alpine3.22
ENV PHP_VERSION=83
RUN sh
RUN chmod 1777 /tmp
RUN chmod -R 1777 /var/tmp
RUN rm -rf /var/lib/apt/lists/*

# update sources list
RUN apk update
RUN apk add --no-cache wget
RUN apk --no-cache add curl

# LDAP system libraries
RUN apk add openldap-back-mdb
RUN apk add --update --virtual .build-deps openldap
RUN apk --update --no-cache add libldap openldap-clients openldap openldap-back-mdb
ARG DOCKER_PHP_ENABLE_LDAP

# basic apps
RUN apk --no-cache add bash \
    cronie \
    git \
    mariadb-client \
    openssh \
    nano \
    patch \
    sudo \
    tmux \
    ldb \
    apache2-utils

# --- BEGIN: upgrade runtime PHP to Alpine edge php83 and wire Drupal to use it ---
RUN set -eux; \
  apk add --no-cache --update-cache \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
    php83 \
    php83-fpm \
    php83-opcache \
    php83-mysqli \
    php83-pdo_mysql \
    php83-ldap \
    php83-gd \
    php83-xml \
    php83-dom \
    php83-simplexml \
    php83-tokenizer \
    php83-session

ENV PHP_INI_DIR=/etc/php83
RUN set -eux; \
  mkdir -p /usr/local/etc; \
  ln -sfn /etc/php83                  /usr/local/etc/php; \
  ln -sf  /usr/bin/php83              /usr/local/bin/php; \
  ln -sf  /usr/sbin/php-fpm83         /usr/local/sbin/php-fpm; \
  ln -sf  /etc/php83/php-fpm.conf     /usr/local/etc/php-fpm.conf; \
  ln -sfn /etc/php83/php-fpm.d        /usr/local/etc/php-fpm.d; \
  php -v && php-fpm -v
# --- END ---

# Enable PHP LDAP extension if not disabled
RUN if [ "${DOCKER_PHP_ENABLE_LDAP}" != "off" ]; then \
      apk add --update --no-cache libldap && \
      apk add --update --no-cache --virtual .docker-php-ldap-dependancies openldap-dev && \
      docker-php-ext-configure ldap && \
      docker-php-ext-install ldap && \
      apk del .docker-php-ldap-dependancies && \
      php -m | grep ldap || true; \
    else \
      echo "Skip ldap support"; \
    fi

COPY ./resources/httpd.conf /etc/apache2/httpd.conf
COPY ./resources/run.sh /usr/bin
COPY ./resources/000-default.conf /etc/apache2/conf.d
COPY ./resources/.htaccess /tmp
COPY ./resources/ldap.conf /etc/openldap
COPY resources/services.yml /tmp
COPY resources/settings.php /tmp
COPY resources/00_php.ini /etc/php$PHP_VERSION/conf.d

RUN chmod 700 /usr/bin/run.sh

WORKDIR /opt/drupal
WORKDIR /opt/drupal/web

RUN echo 'memory_limit = -1' >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini

ENTRYPOINT run.sh
