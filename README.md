# drupal-docker base project: Fedora 45

This package supersedes the earlier combined-project conversion. It converts ONLY the uploaded drupal-docker base project. The downstream Events project still needs its own conversion before it can use this base.

## Changes

- Fedora 45, DNF package names, PHP 8.5, Apache with PHP-FPM.
- PHP INI files copied into /etc/php.d. Existing 4G memory and 200M upload/post limits preserved.
- New php-fpm-container.conf permits the apache user to access the PHP socket and passes ECS environment variables to PHP workers.
- Entrypoint starts and supervises PHP-FPM/Apache without systemd, forwards termination, and skips Drush when Drupal is absent.
- Base build fails unless PHP is 8.5 and its loaded libxml2 is >= 2.15.4.
- SDK install retained at the same root working directory as the original base image.
- buildforaws.sh preserved unchanged. It pushes when YOU invoke it; no build/push was run during conversion.
- installdrupal.sh remains a helper for the child project and is NOT run or copied by this base Dockerfile, matching the original. It now fails on errors, marks installation only after success, and updates Postfix via postconf rather than overwriting main.cf. Use it in the downstream project's build context when converting that project.

## Build and verify locally first

Run from this directory:

```sh
docker build --pull --no-cache --platform linux/amd64 -t drupal-docker:fedora45 .
docker run --rm drupal-docker:fedora45 php -r 'echo PHP_VERSION, " / libxml ", LIBXML_DOTTED_VERSION, PHP_EOL;'
docker run --rm drupal-docker:fedora45 php -m
docker run --rm drupal-docker:fedora45 php --ini
docker run --rm --entrypoint httpd drupal-docker:fedora45 -t
```

For the last syntax-only check use `docker run --rm --entrypoint httpd drupal-docker:fedora45 -t` to bypass the web-service supervisor.

Smoke test the base web server:

```sh
docker run --rm -d --name drupal-base-test -p 8080:80 drupal-docker:fedora45
curl -I http://localhost:8080/
docker logs drupal-base-test
docker stop drupal-base-test
```

The base has no Drupal files/vhost and may return 403 at /. That demonstrates an HTTP response, not a working Drupal site. The inherited healthcheck intentionally keeps the original behavior (checks HTTP transport, not status or Drupal health). Rescan the exact built image in Twistlock.

## Downstream migration still required

- Replace apk installs with Fedora packages or remove modules already covered by this base.
- Port the Alpine Apache configuration to /etc/httpd/conf/httpd.conf and /etc/httpd/conf.d; do not copy Alpine httpd.conf over Fedora defaults.
- Configure the vhost DocumentRoot as /var/www/drupal/web based on the supplied installation script.
- Use the inherited entrypoint (or incorporate its PHP-FPM startup in any replacement).
- Set START_POSTFIX=1 only in the child configured for mail. Remove RUN postfix start from the child Dockerfile.
- Check LDAP trust/config and application behavior after converting the child.

## Validation limits

Shell syntax and file contents were checked. No Docker/Podman executable was available, so package resolution, image build, Apache/PHP-FPM runtime, Drupal/LDAP/mail and Twistlock results have NOT been tested. Package availability is based on Fedora's published package metadata and the build explicitly checks the loaded libxml version.
