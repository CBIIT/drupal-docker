#!/bin/bash
set -Eeuo pipefail

# Explicit commands such as `docker run IMAGE php -v` need no web services.
if [[ "${1:-}" != httpd ]]; then
    exec "$@"
fi

mkdir -p /run/httpd /run/php-fpm
php-fpm --test
httpd -t

# The base image has no Drupal site. Rebuild cache only in a configured child.
if [[ -x "${drupal_root}/vendor/bin/drush" && -f "${drupal_root}/web/sites/default/settings.php" ]]; then
    if ! "${drupal_root}/vendor/bin/drush" --root="${drupal_root}/web" cr; then
        echo 'Warning: Drupal cache rebuild failed; inspect database connectivity and settings.' >&2
    fi
fi

pids=()
cleanup() {
    trap - TERM INT
    if ((${#pids[@]})); then
        kill -TERM "${pids[@]}" 2>/dev/null || true
        wait "${pids[@]}" 2>/dev/null || true
    fi
}
trap 'cleanup; exit 0' TERM INT

# Enable only in child images that configure a mail relay.
if [[ "${START_POSTFIX:-0}" == 1 ]]; then
    postfix start-fg &
    pids+=("$!")
fi
php-fpm --nodaemonize &
pids+=("$!")
"$@" &
pids+=("$!")

# If either web process exits, stop its peers and let ECS restart the task.
status=0
wait -n "${pids[@]}" || status=$?
cleanup
exit "$status"
