# .bashrc
PS1='[\[\e[1m\u\[\e[0m\]@$database:\[\e[1m\]\w\[\e[0m\]\$] '
cd /local/drupal/site
drush status

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
