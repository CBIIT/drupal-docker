# Install Site
if [[ -z $dbname ]]; then
    DBNAME=$(echo $RANDOM | md5sum | head -c 20; echo;)
    drush si --db-url=mysql://root:password@192.168.0.178:3306/$DBNAME --site-name=Default --account-name=bob --account-pass=bob -y

else
    drush si --db-url=mysql://root:password@192.168.0.178:3306/$dbname --site-name=$sitename --account-name=bob --account-pass=bob -y
fi
chown -R apache:apache /opt/drupal/web/sites/default
#Start Apache
exec httpd -DFOREGROUND
