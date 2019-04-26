EXPORT PS1='[\[\e[1m\u\[\e[0m\]@$database:\[\e[1m\]\w\[\e[0m\]\$] '
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
    cp /tmp/settings.php /local/drupal/site/web/sites/default
    cp /tmp/.htaccess /local/drupal/site
fi

exec httpd -DFOREGROUND
