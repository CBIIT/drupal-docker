FROM alpine:latest

# Enable edge repos so php83=8.3.25-r0 is available
# RUN set -eux; \
#   echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories; \
#   echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories;
RUN apk update

ARG code_path=/tmp/github
ARG phpversion=8.3
ARG drupal_root=/var/www/drupal
ENV code_path=${code_path}
ENV drupal_root=${drupal_root}

# Install deps + PHP 8.3.25 (pinned)
RUN apk add --no-cache git curl openldap openldap-clients composer \
    patch vim mariadb-client postfix \
    # php83=${phpversion} \
    # php83-ldap=${phpversion} \
    # php83-apache2=${phpversion} \
    # php83-opcache=${phpversion} \
    # php83-mysqli=${phpversion} \
    # php83-pdo_mysql=${phpversion} \
    # php83-tokenizer=${phpversion} \
    # php83-dom=${phpversion} \
    # php83-gd=${phpversion} \
    # php83-pdo=${phpversion} \
    # php83-session=${phpversion} \
    # php83-simplexml=${phpversion} \
    # php83-xml=${phpversion}
    php83 \
    php83-ldap \
    php83-apache2 \
    php83-opcache \
    php83-mysqli \
    php83-pdo_mysql \
    php83-dom \
    php83-gd \
    php83-pdo \
    php83-session \
    php83-simplexml \
    php83-xml    

RUN mkdir -p /var/www/drupal /run/apache2
RUN ln -sf ${drupal_root}/vendor/bin/drush /usr/bin/drush
RUN composer require aws/aws-sdk-php

COPY memory.ini /etc/php83/conf.d/
COPY 00_filesize.ini /etc/php83/conf.d/
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

WORKDIR ${drupal_root}
EXPOSE 80

# Valid healthcheck flags (removed unsupported --start-interval)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=4 \
  CMD curl -sS -o /dev/null http://127.0.0.1:80/ || exit 1

# Run Apache in foreground (the "&" is unnecessary and harmful in JSON CMD)
CMD ["httpd", "-D", "FOREGROUND"]
