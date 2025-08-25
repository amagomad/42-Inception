#!/bin/bash
set -e

# Crée le dossier runtime de php-fpm
mkdir -p /run/php

# Si le volume /var/www/html est vide → copie WordPress depuis /usr/src
if [ -z "$(ls -A /var/www/html 2>/dev/null)" ]; then
  echo "[wp] /var/www/html est vide → copie des fichiers WordPress"
  cp -a /usr/src/wordpress/* /var/www/html/
  chown -R www-data:www-data /var/www/html
else
  echo "[wp] /var/www/html existe déjà → rien à copier"
fi

# Lance php-fpm en mode foreground
exec php-fpm7.4 -F
