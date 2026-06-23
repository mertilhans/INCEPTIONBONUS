FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl php-fpm php-mysql php-redis \
    && curl -o /usr/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/bin/wp \
    && mkdir -p /var/www/wordpress \
    && rm -rf /var/lib/apt/lists/*

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/wp-config.sh /wp-config.sh

ENTRYPOINT ["sh", "/wp-config.sh"]
