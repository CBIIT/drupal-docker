if [[ -z $repository ]]; then
    echo "Create new drupal site"
    echo "Adding drupaldocker user"
    groupadd -g 3000 drupaldocker
    useradd -c "" -d /home/drupaldocker -s /bin/bash -g 3000 -u 3000 drupaldocker
    composer create-project drupal/recommended-project:9.2.6 site

    #composer create-project drupal-composer/drupal-project:8.x-dev /local/drupal/site --no-interaction
    cd /local/drupal/site
    echo "installing drush"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --install-dir=/usr/bin --filename=composer
    composer require drush/drush:^10
    echo "end installing drush"
    echo "loading database"
    #drush sql-cli < /tmp/newdatabase8.9.16.sql
    echo "end loading database"
    #drush si standard —-db-url=mysql://dbuser:dbpassword@server:3306/drpual9 --site-name=testDrupal9  --account-name=admin --account-pass=admin123 --site-mail=seinolf@gmail.com
    cp /tmp/settings.php /local/drupal/site/web/sites/default
    chown -R drupaldocker:drupaldocker /local/drupal

else
    echo "navigate to site directory"
    if [ -d "/local/drupal/site/vendor" ]; then
        echo "Skipping site download"
        cd /local/drupal/site
        echo "pulling latest code from $repository"
        git pull
    else
        echo "Adding drupaldocker user"
        groupadd -g 3000 drupaldocker
        useradd -c "" -d /home/drupaldocker -s /bin/bash -g 3000 -u 3000 drupaldocker
        #usermod -G apache drupaldocker
        #usermod -G drupaldocker apache

        echo "Cloning code from $repository"
        mkdir site
        cd site
        git init
        git remote add  origin $repository
        branchOrTag="${CONTAINER_BRANCH_OR_TAG/origin*\//}"
        echo "#####"$branchOrTag"####"
        git pull origin $branchOrTag
        git pull
        git config --global user.email "you@example.com"
        git config --global user.name "Your Name"
        git stash
        git checkout $branchOrTag
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
        if $load_database; then
	    zipped_db=/local/drupal/site/database.sql.zip
	    if [ -f "$zipped_db" ]; then
    	        unzip $zipped_db
	    fi
            echo "* Load Database"
            drush sql-cli < /local/drupal/site/database.sql
        else
            echo "* Skipping Database Load"
        fi

        echo "Peform this after loading database or importing config"
        echo ""
        echo "* Setting up ldap server and port, turning on ldap_authentication"

        drupal_version=$(echo $(drush status | grep 'Drupal version') | sed 's/Drupal version : //')
        if [[ $drupal_version = 9* ]]
            then
                ldap_address_no_ldaps=$(echo "$ldap_address"  | sed -r 's/ldaps:\/\///g')
                drush cset ldap_servers.server.nci address $ldap_address_no_ldaps -y
            else
                drush cset ldap_servers.server.nci address $ldap_address -y
        fi
        drush cset ldap_servers.server.nci port $ldap_port -y
        echo "* Enable ldap_authentication"
        drush pm-enable ldap_authentication -y
        drush cset ldap_authentication.settings sids.nci nci -y
        drush cset ldap_authentication.settings skipAdministrators 0 -y
        drush updb -y
        drush updatedb --entity-updates -y
        drush cr
        setup/setup_prod.sh

    fi

    cp /tmp/settings.php /local/drupal/site/web/sites/default
    cp /tmp/.htaccess /local/drupal/site
    cp /tmp/.htaccess /local/drupal/tmp
    cp /tmp/services.yml /local/drupal/site/web/sites/default
    chmod 644 /local/drupal/site/web/sites/default/settings.php /local/drupal/site/web/sites/default/services.yml /local/drupal/tmp/.htaccess

    if [ -d "/local/drupal/site/docker/apache" ];then
 	    echo "Adding addition apache config files"
 	    cp /local/drupal/site/docker/apache/* /etc/httpd/conf.d
    fi

fi

if [ -n "$local_build" ]; then
    sed -i 's/nci.nih.gov/localhost/g' /local/drupal/site/web/sites/default/services.yml
fi
echo "redirecting apache logs to /dev/stderr and /dev/stdout to allow them to show up in docker log"
ln -sf /dev/stderr /var/log/httpd/error.log
ln -sf /dev/stdout /var/log/httpd/access.log

echo "starting crond"
crond && tail -f /dev/null &
echo "done starting crond"
drush cr
echo "start apache"
exec httpd -DFOREGROUND
