#!/bin/sh
set -eu
: "${code_path:?code_path must be set}"
: "${drupal_root:?drupal_root must be set}"
cd "$drupal_root"

if [ -f installed.txt ]; then
    echo 'Drupal Site Already Installed'
    exit 0
fi

cp "$code_path/docker/composer.lock" ./
cp "$code_path/docker/composer.json" ./
cp -r "$code_path/docker/web" ./
cp "$code_path/docker/htaccess.patch" ./web/
composer config --no-plugins allow-plugins.cweagans/composer-patches true
composer install --no-interaction --no-progress
cp web/sites/default/default.settings.php web/sites/default/settings.php
# Preserve the packaged Postfix configuration; change only the relay setting.
postconf -e 'relayhost = [mailfwd.nih.gov]'
cat "$code_path/docker/settings.php.patch" >> web/sites/default/settings.php
mkdir -p config/sync
chown -R apache:apache web
# Mark successful installation only after all preceding commands succeed.
touch installed.txt
