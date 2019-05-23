FROM ncidockerhub.nci.nih.gov/cbiit/centos7_base

ENV DRUPAL_VERSION=8.7.1

# Update image #
RUN yum -y update \
    && yum -y install yum-utils wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm epel-release yum-utils \
    && yum-config-manager --disable remi-php54 \
    && yum-config-manager --enable remi-php73 \
    && yum install -y git php php-cli php-fpm php-mysqlnd \
       php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-ldap \
       php-xml php-pear php-bcmath patch php-json php-pecl-xdebug.x86_64 composer which vi mariadb unzip patch openldap openldap-clients openldap-devel

# Install drush using composer/cgr #
#RUN composer global require consolidation/cgr 
ENV PATH="/local/drupal/site/vendor/drush/drush:$PATH"
#RUN cgr drush/drush:8.x


# Get Drupal #
RUN mkdir -p /local/drupal
WORKDIR /local/drupal
#RUN drush dl drupal-$DRUPAL_VERSION --drupal-project-rename="site"

# COPY main resouces over #
COPY resources/run.sh /usr/bin
COPY resources/000-default.conf /etc/httpd/conf.d
COPY resources/httpd.conf /etc/httpd/conf
COPY resources/settings.php /tmp
COPY resources/.htaccess /tmp
RUN chmod 700 /usr/bin/run.sh
EXPOSE 80
ADD resources/.bashrc /root
WORKDIR /local/drupal
ENTRYPOINT run.sh
