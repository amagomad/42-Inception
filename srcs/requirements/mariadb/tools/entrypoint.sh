#!/bin/sh
set -e

# Lire les secrets si fournis (sinon garder les envs)
[ -n "$MYSQL_ROOT_PASSWORD_FILE" ] && [ -f "$MYSQL_ROOT_PASSWORD_FILE" ] && MYSQL_ROOT_PASSWORD="$(cat "$MYSQL_ROOT_PASSWORD_FILE")"
[ -n "$MYSQL_PASSWORD_FILE" ] && [ -f "$MYSQL_PASSWORD_FILE" ] && MYSQL_PASSWORD="$(cat "$MYSQL_PASSWORD_FILE")"

# Prépare les répertoires runtime/datadir
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Si la base système n'existe pas, on initialise le datadir
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "[mariadb] Initialisation du datadir..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db >/dev/null

  # Démarre mysqld en local (pas de réseau) pour configurer root/DB/user
  mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
  pid="$!"

  # Attend que le socket réponde
  for i in $(seq 1 30); do
    mariadb -uroot --socket=/run/mysqld/mysqld.sock -e "SELECT 1" >/dev/null 2>&1 && break
    sleep 1
  done

  # Valeurs par défaut si non fournies (pratique en test docker run)
  : "${MYSQL_DATABASE:=wordpress}"
  : "${MYSQL_USER:=wp_user}"
  : "${MYSQL_PASSWORD:=wp_pass}"
  : "${MYSQL_ROOT_PASSWORD:=rootpass}"

  echo "[mariadb] Création DB/utilisateur..."
  mariadb -uroot --socket=/run/mysqld/mysqld.sock <<-SQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
SQL

  # Coupe le mysqld temporaire
  kill "$pid"; wait "$pid" 2>/dev/null || true
fi

# Lance le serveur "pour de vrai" en avant-plan (PID1)
exec mysqld --user=mysql --datadir=/var/lib/mysql --console

