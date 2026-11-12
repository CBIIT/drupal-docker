FROM fedora:45

ARG code_path=/tmp/github
ARG drupal_root=/var/www/drupal
ENV code_path=${code_path} \
    drupal_root=${drupal_root} \
    COMPOSER_ALLOW_SUPERUSER=1

# Preserve the existing PHP 8.5 branch; use Fedora's Apache + PHP-FPM.
RUN dnf upgrade --refresh -y \
    && dnf install -y --setopt=install_weak_deps=False \
       bash git curl-minimal openldap openldap-clients composer \
       patch vim-minimal mariadb postfix httpd httpd-tools \
       php-cli php-common php-fpm php-ldap php-mysqlnd php-pdo \
       php-gd php-xml php-process php-mbstring php-intl php-pecl-zip \
       'libxml2 >= 2.15.4' \
    && dnf clean all \
    && rm -rf /var/cache/dnf \
    && php -r 'if (PHP_MAJOR_VERSION !== 8 || PHP_MINOR_VERSION !== 5 || LIBXML_VERSION < 21504) { fwrite(STDERR, "Expected PHP 8.5 and libxml2 >= 2.15.4\n"); exit(1); }'

RUN mkdir -p "${drupal_root}" /run/httpd /run/php-fpm \
    && ln -sf "${drupal_root}/vendor/bin/drush" /usr/bin/drush \
    && ln -sf /usr/bin/php /usr/bin/php85 \
    && rm -f /etc/httpd/conf.d/welcome.conf \
    && printf '%s\n' 'ServerName localhost' > /etc/httpd/conf.d/servername.conf

# Preserve the original base-image AWS SDK install at /composer.json.
# Application dependencies should ultimately live in its own composer.lock.
WORKDIR /
RUN composer require aws/aws-sdk-php --no-interaction --no-progress

COPY memory.ini 00_filesize.ini /etc/php.d/
COPY php-fpm-container.conf /etc/php-fpm.d/zz-container.conf
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh \
    && php-fpm --test \
    && httpd -t

WORKDIR ${drupal_root}
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=4 \
  CMD curl -sS -o /dev/null http://127.0.0.1:80/ || exit 1

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]
