FROM alpine:latest

RUN apk update

ARG code_path=/tmp/github
ARG phpversion=8.4
ARG drupal_root=/var/www/drupal
ENV code_path=${code_path}
ENV drupal_root=${drupal_root}

RUN apk add --no-cache \
  openldap \
  openldap-clients \
  patch \
  vim \
  mariadb-client \
  postfix \
  curl \
  php84 \
  php84-apache2 \
  php84-opcache \
  php84-mysqli \
  php84-pdo_mysql \
  php84-ldap \
  php84-dom \
  php84-gd \
  php84-tokenizer \
  php84-session \
  php84-simplexml \
  php84-xml \
  php84-pecl-redis \
  php84-phar \
  php84-iconv \
  php84-openssl
  
RUN curl -sS https://getcomposer.org/installer \
  | php84 -- --install-dir=/usr/local/bin --filename=composer
    
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
