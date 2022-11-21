# Install Site
user="${user:-admin}"
pass="${pass:-admin}"

dbname="${database:-$(echo $RANDOM | md5sum | head -c 20; echo;)}"
dbhost="${host:-localhost}"
dbport="${port:-3306}"
dbuser="${username:-default}"
dbpass="${password:-default}"
sitename="${sitename:-default}"
FILE=/opt/drupal/installed
echo "Adding drupaldocker user"
addgroup -g 3000 drupaldocker
adduser -S -D -u  3000 -s /bin/bash  -h /home/drupaldocker -G drupaldocker drupaldocker
if [ -f "$FILE" ]; then
    echo "Drupal Site Already Installed"
else
    if [ -n "$repository" ]; then
        ## If repo we are installing an existing site ##
        echo "Cloning code from $repository"
        branchOrTag="${CONTAINER_BRANCH_OR_TAG/origin*\//}"
        cd /opt
        rm -rf /opt/drupal
        git config --global user.email "you@example.com"
        git config --global user.name "Your Name"
        git clone $repository drupal
        cd drupal
        git checkout $branchOrTag
        mkdir /opt/drupal/web/sites/files
        mkdir /opt/drupal/web/sites/files/config
        chown -R drupaldocker:drupaldocker /opt/drupal/web/sites/files

        composer install

        cp /tmp/settings.php /opt/drupal/web/sites/default
        cp /tmp/services.yml /opt/drupal/web/sites/default
        cp /tmp/.htaccess /opt/drupal
        touch /opt/drupal/installed
        chown -R drupaldocker:drupaldocker /opt/drupal
	if [ -d "/opt/drupal/docker/apache" ];then
		echo "Adding addition apache config files"
		cp /opt/drupal/docker/apache/*.conf /etc/apache2/conf.d
		if [ -f "/opt/drupal/docker/apache/footer.html" ]; then
			cp /opt/drupal/docker/apache/footer.html /mnt/s3fs/ftp1
		fi
	fi	
        if [ -d "/opt/drupal/docker/cron" ];then
            echo "Adding cronjob file"
            cp /opt/drupal/docker/cron/drupal.cron /etc/cron.d
            chmod 0644 /etc/cron.d/drupal.cron
            crontab /etc/cron.d/drupal.cron
        fi	
        if $load_database; then
	        zipped_db=/opt/drupal/database.sql.zip
	    if [ -f "$zipped_db" ]; then
    	    unzip $zipped_db
	    fi
            echo "* Load Database"
            drush sql-cli < /opt/drupal/database.sql
        else
            echo "* Skipping Database Load"
        fi
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
    else
        ## If no repo we are installing a new site ##
        mysql -u$dbuser -p$dbpass -h$dbhost -P$dbport -e "drop database $dbname"
        mysql -u$dbuser -p$dbpass -h$dbhost -P$dbport -e "create database $dbname"
        cp /tmp/services.yml /opt/drupal/web/sites/default
        cp /tmp/settings.php /opt/drupal/web/sites/default
        drush -y si --db-url=mysql://$dbuser:$dbpass@$dbhost:$dbport/$dbname --site-name=$dbname --account-name=$user --account-pass=$pass
        chown -R drupaldocker:drupaldocker /opt/drupal

    fi

fi
#Start Apache
if [ -n "$local_build" ]; then
    sed -i 's/nci.nih.gov/localhost/g' /opt/drupal/web/sites/default/services.yml
fi
drush cr
exec httpd -DFOREGROUND
