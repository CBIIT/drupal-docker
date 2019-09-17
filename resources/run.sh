if [[ -z $repository ]]; then
    echo "Create new drupal site"
    composer create-project drupal-composer/drupal-project:8.x-dev /local/drupal/site --no-interaction
    cd /local/drupal/site
    composer upgrade drupal/core:$DRUPAL_VERSION  --with-dependencie    
else
    echo "navigate to site directory"
    if [ -d "/local/drupal/site/vendor" ]; then
        echo "Skipping site download"
        cd /local/drupal/site
        echo "pulling latest code from $repository"
        git pull
    else
        
        echo "Cloning code from $repository"
        mkdir site
        cd site
        git init
        git remote add  origin $repository
        git pull origin master
        composer install
        echo "*Setting up directory permissions"
        chown -R root:apache /local/drupal
        echo "chmod -R 775 /local/drupal/site/web/sites/default/files"
        chmod -R 775 /local/drupal/site/web/sites/default/files
        echo "chmod -R 664 /local/drupal/site/web/sites/default/s*"
        chmod 664 /local/drupal/site/web/sites/default/s*
        echo "Create private directory /local/drupal/site/private-files"
        mkdir /local/drupal/site/private-files
        chown -R root:apache /local/drupal/site/private-files
        chmod -R 664 /local/drupal/site/private-files
    fi
    #drush cim -y
    #drush cset ldap_servers.server.eventsldap address $ldap_address
    #drush cset ldap_servers.server.eventsldap port $ldap_port
    #git config --global color.ui auto

    cp /tmp/settings.php /local/drupal/site/web/sites/default
    cp /tmp/.htaccess /local/drupal/site
    cp /tmp/services.yml /local/drupal/site/web/sites/default
    if [ -d "/local/drupal/site/docker/apache" ];then
 	    echo "Adding addition apache config files"
 	    cp /local/drupal/site/docker/apache/* /etc/httpd/conf.d
    fi
fi

echo "redirecting apache logs to /dev/stderr and /dev/stdout to allow them to show up in docker log"
ln -sf /dev/stderr /var/log/httpd/error.log
ln -sf /dev/stdout /var/log/httpd/access.log

echo "start apache"
exec httpd -DFOREGROUND
