FROM alpine:latest

# Enable edge repos so php84=8.3.25-r0 is available
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
    # php84=${phpversion} \
    # php84-ldap=${phpversion} \
    # php84-apache2=${phpversion} \
    # php84-opcache=${phpversion} \
    # php84-mysqli=${phpversion} \
    # php84-pdo_mysql=${phpversion} \
    # php84-tokenizer=${phpversion} \
    # php84-dom=${phpversion} \
    # php84-gd=${phpversion} \
    # php84-pdo=${phpversion} \
    # php84-session=${phpversion} \
    # php84-simplexml=${phpversion} \
    # php84-xml=${phpversion}
    php84 \
    php84-ldap \
    php84-apache2 \
    php84-opcache \
    php84-mysqli \
    php84-pdo_mysql \
    php84-dom \
    php84-gd \
    php84-pdo \
    php84-session \
    php84-simplexml \
    php84-tokenizer \
    php84-xml

RUN mkdir -p /var/www/drupal /run/apache2
RUN ln -sf ${drupal_root}/vendor/bin/drush /usr/bin/drush
RUN composer require aws/aws-sdk-php

COPY memory.ini /etc/php84/conf.d/
COPY 00_filesize.ini /etc/php84/conf.d/
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

WORKDIR ${drupal_root}
EXPOSE 80

# Valid healthcheck flags (removed unsupported --start-interval)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=4 \
  CMD curl -sS -o /dev/null http://127.0.0.1:80/ || exit 1

# Run Apache in foreground (the "&" is unnecessary and harmful in JSON CMD)
CMD ["httpd", "-D", "FOREGROUND"]
