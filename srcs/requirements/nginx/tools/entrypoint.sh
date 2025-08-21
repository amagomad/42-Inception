#!/bin/sh
set -e

if [ ! -f /etc/ssl/private/amagomad.42.fr.key ]; then
    mkdir -p /etc/ssl/private /etc/ssl/certs
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/ssl/private/amagomad.42.fr.key \
        -out /etc/ssl/certs/amagomad.42.fr.crt \
        -subj "/CN=amagomad.42.fr"
fi

# Petite page de test
echo "<h1>Hello from Nginx (SSL OK)</h1>" > /var/www/html/index.html

exec "$@"

