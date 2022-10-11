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
        chown -R apache:apache /opt/drupal/web/sites/files

        composer install

        cp /tmp/settings.php /opt/drupal/web/sites/default
        cp /tmp/services.yml /opt/drupal/web/sites/default
        cp /tmp/.htaccess /opt/drupal
        touch /opt/drupal/installed
        chown -R apache:apache /opt/drupal
        if $load_database; then
	        zipped_db=/local/drupal/site/database.sql.zip
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
        drush si --db-url=mysql://$dbuser:$dbpass@$dbhost:$dbport/$dbname --site-name=$sitename --account-name=$user --account-pass=$pass
    fi

fi

#Start Apache
if [ -n "$local_build" ]; then
    sed -i 's/nci.nih.gov/localhost/g' /opt/drupal/web/sites/default/services.yml
fi
exec httpd -DFOREGROUND
