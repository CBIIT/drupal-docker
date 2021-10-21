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
RUN apk add  git
RUN apk add  nano
RUN apk add  tmux
RUN apk add  sudo
RUN apk add  curl
RUN apk add  openssh
RUN apk add  bash
RUN apk add php7-apache2
RUN apk add php7-json
RUN apk add php7-dom
RUN apk add php7-gd
RUN apk add php7-pdo
RUN apk add php7-session
RUN apk add php7-simplexml
RUN apk add php7-xml
RUN apk add php7-pdo_mysql
RUN apk add php7-tokenizer
ADD ./resources/httpd_alpine.conf /etc/apache2/httpd.conf

