FROM drupal:9.4.8-php8.1-fpm-alpine3.16
ENV PHP_VERSION=81
RUN sh
RUN chmod 1777 /tmp
RUN chmod -R 1777 /var/tmp
RUN rm -rf /var/lib/apt/lists/*

# update sources list
RUN apk update
RUN apk add --no-cache ca-certificates wget && update-ca-certificates
COPY ./resources/CA.cer /usr/local/share/ca-certificates/CA.crt
COPY ./resources/ROOT.cer /usr/local/share/ca-certificates/ROOT.crt
RUN cat /usr/local/share/ca-certificates/CA.crt >> /etc/ssl/certs/ca-certificates.crt
RUN cat /usr/local/share/ca-certificates/ROOT.crt >> /etc/ssl/certs/ca-certificates.crt
RUN apk --no-cache add curl

RUN apk add openldap-back-mdb
RUN apk add --update --virtual .build-deps openldap
RUN apk --update --no-cache add libldap openldap-clients openldap openldap-back-mdb
ARG DOCKER_PHP_ENABLE_LDAP


# install basic apps, one per line for better caching
RUN apk --no-cache add bash \
    cronie \
    git \
    mariadb-client \
    openssh \
    nano \
    patch \
    sudo \
    tmux \
    ldb-dev \
    php${PHP_VERSION}-apache2 \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-pdo_mysql \
    php${PHP_VERSION}-session \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-tokenizer \
    php${PHP_VERSION}-xml \
    apache2-utils
RUN apk upgrade
# Enable LDAP
RUN if [ "${DOCKER_PHP_ENABLE_LDAP}" != "off" ]; then \
      # Dependancy for ldap \
      apk add --update --no-cache \
          libldap && \
      # Build dependancy for ldap \
      apk add --update --no-cache --virtual .docker-php-ldap-dependancies \
          openldap-dev && \
      docker-php-ext-configure ldap && \
      docker-php-ext-install ldap && \
      apk del .docker-php-ldap-dependancies && \
      php -m; \
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

RUN chmod 700 /usr/bin/run.sh
WORKDIR /opt/drupal
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/bin --filename=composer
COPY ./resources/composer.json /opt/drupal

RUN composer --no-interaction require drush/drush:^10 --prefer-dist
RUN composer --no-interaction update
WORKDIR /opt/drupal/web
RUN echo 'memory_limit = -1' >> /usr/local/etc/php/conf.d/docker-php-ram-limit.ini
ENTRYPOINT run.sh


