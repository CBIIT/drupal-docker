
echo "Adding drupaldocker user"
groupadd -g 3000 drupaldocker
useradd -c "" -d /home/drupaldocker -s /bin/bash -g 3000 -u 3000 drupaldocker
cp -R /tmp/nci-cct-eventsreg /local/drupal
mv /local/drupal/nci-cct-eventsreg /local/drupal/site
cd site
composer install
#echo "start apache"
#exec httpd -DFOREGROUND
#httpd -V
cp /tmp/settings.php /local/drupal/site/web/sites/default
cp /tmp/.htaccess /local/drupal/site
cp /tmp/services.yml /local/drupal/site/web/sites/default
if [ -d "/local/drupal/site/docker/apache" ];then
    echo "Adding addition apache config files"
    cp /local/drupal/site/docker/apache/* /etc/httpd/conf.d
fi
# name the cron job file drupal.cron #
if [ -d "/local/drupal/site/docker/cron" ];then
    echo "Adding cronjob file"
    cp /local/drupal/site/docker/cron/drupal.cron /etc/cron.d
    chmod 0644 /etc/cron.d/drupal.cron
    crontab /etc/cron.d/drupal.cron
fi
echo "*Setting up directory permissions"
#chown -R root:apache /local/drupal
chown -R drupaldocker:drupaldocker /local/drupal

echo "chmod -R 775 /local/drupal/site/web/sites/default/files"
chmod -R 775 /local/drupal/site/web/sites/default/files
echo "chmod -R 664 /local/drupal/site/web/sites/default/s*"
chmod 664 /local/drupal/site/web/sites/default/s*
echo "Create private directory /local/drupal/site/private-files"
mkdir /local/drupal/site/private-files
chown -R drupaldocker:drupaldocker /local/drupal/site/private-files
chmod -R 664 /local/drupal/site/private-files
echo "Create tmp directory /local/drupal/tmp"
mkdir /local/drupal/tmp
chown -R drupaldocker:drupaldocker /local/drupal/tmp
chmod -R 775 /local/drupal/tmp
echo ""
echo "Adding drush commands in run.sh"
cd /local/drupal/site
# if $load_database; then
#     echo "* Load Database"
#     drush sql-cli < /local/drupal/site/database.sql
# else
#     echo "* Skipping Database Load"
# fi



cp /tmp/settings.php /local/drupal/site/web/sites/default
cp /tmp/.htaccess /local/drupal/site
cp /tmp/.htaccess /local/drupal/tmp
cp /tmp/services.yml /local/drupal/site/web/sites/default
chmod 644 /local/drupal/site/web/sites/default/settings.php /local/drupal/site/web/sites/default/services.yml /local/drupal/tmp/.htaccess

if [ -d "/local/drupal/site/docker/apache" ];then
    echo "Adding addition apache config files"
    cp /local/drupal/site/docker/apache/* /etc/httpd/conf.d
fi
echo "redirecting apache logs to /dev/stderr and /dev/stdout to allow them to show up in docker log"
ln -sf /dev/stderr /var/log/httpd/error.log
ln -sf /dev/stdout /var/log/httpd/access.log

echo "starting crond"
crond && tail -f /dev/null &
echo "done starting crond"

echo "start apache"
exec httpd -DFOREGROUND

