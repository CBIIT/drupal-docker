FROM drupal:9.2.7-php7.4-fpm-alpine3.14
ENV DRUPAL_VERSION=9.2.6

RUN sh
RUN chmod 1777 /tmp
RUN chmod -R 1777 /var/tmp
RUN rm -rf /var/lib/apt/lists/*

# update sources list
RUN apk update && apk upgrade
RUN apk add ca-certificates wget && update-ca-certificates

# install basic apps, one per line for better caching
RUN apk add bash git nano tmux sudo curl openssh php7-apache2 php7-json php7-dom php7-gd php7-pdo php7-session php7-simplexml php7-xml php7-pdo_mysql php7-tokenizer

COPY ./resources/httpd_alpine.conf /etc/apache2/httpd.conf
COPY ./resources/run.sh /usr/bin
RUN chmod 700 /usr/bin/run.sh
RUN chown -R apache:apache /opt/drupal/web/sites
ENTRYPOINT run.sh


