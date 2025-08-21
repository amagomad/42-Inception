FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php-fpm php-mysql wget curl tar \
 && rm -rf /var/lib/apt/lists/*

# On prépare les dossiers
RUN mkdir -p /usr/src/wordpress /var/www/html

# Télécharge WordPress et le garde dans /usr/src
RUN wget -O /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz \
 && tar -xzf /tmp/wp.tar.gz -C /usr/src \
 && rm /tmp/wp.tar.gz \
 && chown -R www-data:www-data /usr/src/wordpress /var/www/html

# Ajout des configs PHP
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Ajout de l'entrypoint
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["entrypoint.sh"]
