#!/bin/sh
set -e

echo "[wp] boot…"

# ---- Secrets (lus via volume /run/secrets) ----
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-wpuser}"
DB_PASS="$(cat /run/secrets/db_password.txt 2>/dev/null || true)"
DB_HOST="${DB_HOST:-mariadb:3306}"

if [ -z "$DB_PASS" ]; then
  echo "[wp] ERROR: /run/secrets/db_password.txt manquant"
  exit 1
fi

# ---- Installe WordPress si il existe pas ----
if [ ! -f /var/www/html/wp-includes/version.php ]; then
  echo "[wp] /var/www/html ne contient pas WordPress -> copie"
  mkdir -p /var/www/html
  if [ -d /usr/src/wordpress ]; then
    cp -a /usr/src/wordpress/. /var/www/html/
  else
    wget -O /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz
    tar -xzf /tmp/wp.tar.gz -C /tmp
    cp -a /tmp/wordpress/. /var/www/html/
    rm -f /tmp/wp.tar.gz
  fi
  chown -R www-data:www-data /var/www/html
else
  echo "[wp] WordPress déjà présent -> ok"
fi

# ---- Genere wp-config.php si il existe pas ----
if [ ! -f /var/www/html/wp-config.php ]; then
  echo "[wp] Génération wp-config.php"
  cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
  sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php
  sed -i "s/username_here/${DB_USER}/" /var/www/html/wp-config.php
  sed -i "s/password_here/${DB_PASS}/" /var/www/html/wp-config.php
  sed -i "s/localhost/${DB_HOST}/" /var/www/html/wp-config.php
  chown www-data:www-data /var/www/html/wp-config.php
fi

# ---- Attends MariaDB ----
echo "[wp] Attente de MariaDB @ ${DB_HOST}…"
tries=30
while ! php -r "mysqli_connect('${DB_HOST%%:*}','${DB_USER}','${DB_PASS}','${DB_NAME}');" 2>/dev/null; do
  tries=$((tries-1))
  [ $tries -le 0 ] && { echo '[wp] MariaDB KO'; exit 1; }
  sleep 1
done
echo "[wp] MariaDB OK"

# ---- Lance php-fpm en foreground ----
echo "[wp] start php-fpm"
exec php-fpm7.4 -F
