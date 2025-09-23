FROM alpine:latest

# Enable edge repos so php83=8.3.25-r0 is available
RUN set -eux; \
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories; \
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
  apk update

ARG code_path=/tmp/github
ARG drupal_root=/var/www/drupal
ENV code_path=${code_path}
ENV drupal_root=${drupal_root}

# Install deps + PHP 8.3.25 (pinned)
RUN apk add --no-cache git curl openldap openldap-clients composer \
    patch vim mariadb-client postfix \
    php83=8.3.25-r0 \
    php83-ldap=8.3.25-r0 \
    php83-apache2=8.3.25-r0 \
    php83-opcache=8.3.25-r0 \
    php83-mysqli=8.3.25-r0 \
    php83-pdo_mysql=8.3.25-r0 \
    php83-tokenizer=8.3.25-r0 \
    php83-dom=8.3.25-r0 \
    php83-gd=8.3.25-r0 \
    php83-pdo=8.3.25-r0 \
    php83-session=8.3.25-r0 \
    php83-simplexml=8.3.25-r0 \
    php83-xml=8.3.25-r0

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
HEALTHCHECK --interval=5m --timeout=10s --start-period=3m --retries=3 \
  CMD curl -fsS http://127.0.0.1:80/ || exit 1

# Run Apache in foreground (the "&" is unnecessary and harmful in JSON CMD)
CMD ["httpd", "-D", "FOREGROUND"]
