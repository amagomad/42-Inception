#!/bin/sh
set -e

echo "[db] boot…"

DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-wpuser}"
DB_PASS="$(cat /run/secrets/db_password.txt 2>/dev/null || true)"
DB_ROOT_PASS="$(cat /run/secrets/db_root_password.txt 2>/dev/null || true)"

if [ -z "$DB_PASS" ] || [ -z "$DB_ROOT_PASS" ]; then
  echo "[db] ERROR: secrets manquants dans /run/secrets"
  exit 1
fi

if [ ! -d /var/lib/mysql/mysql ]; then
  echo "[db] init datadir"
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

  echo "[db] bootstrap SQL"
  mysqld --user=mysql --bootstrap <<-SQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
    CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
    GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
    FLUSH PRIVILEGES;
SQL
fi

echo "[db] start mysqld"
exec mysqld --user=mysql
