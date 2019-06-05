if [[ -z $repository ]]; then
    echo "Create new drupal site"
    composer create-project drupal-composer/drupal-project:8.x-dev /local/drupal/site --no-interaction
    cd /local/drupal/site
    composer upgrade drupal/core:$DRUPAL_VERSION  --with-dependencie    
else
    if [ -d "/local/drupal/site" ]; then
        echo "Skipping site download"
        cd /local/drupal/site
        echo "pulling latest code from $repository"
        git pull
    else
        echo "Cloning code from $repository"
        git clone $repository site
        cd site
        composer require drush/drush
    fi
    drush cim -y
    drush cset ldap_servers.server.eventsldap address $ldap_address
    drush cset ldap_servers.server.eventsldap port $ldap_port
    git config --global color.ui auto

    cp /tmp/settings.php /local/drupal/site/web/sites/default
    cp /tmp/.htaccess /local/drupal/site
fi

exec httpd -DFOREGROUND
