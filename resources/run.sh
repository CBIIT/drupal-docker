# Install Site
user="${user:-admin}"
pass="${pass:-admin}"

dbname="${dbname:-$(echo $RANDOM | md5sum | head -c 20; echo;)}"
dbhost="${dbhost:-localhost}"
dbport="${dbport:-3306}"
dbuser="${dbuser:-default}"
dbpass="${dbpass:-default}"
sitename="${sitename:-default}"
FILE=/opt/drupal/installed
if [ -f "$FILE" ]; then
    echo "Drupal Site Already Installed"
else
    drush si --db-url=mysql://$dbuser:$dbpass@$dbhost:$dbport/$dbname --site-name=$sitename --account-name=$user --account-pass=$pass
    touch /opt/drupal/installed
    chown -R apache:apache /opt/drupal
fi
#Start Apache
exec httpd -DFOREGROUND
