FROM debian:bookworm

RUN apt-get update && apt-get install -y curl php-fpm php-mysql \
    && curl -o /usr/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/bin/wp && mkdir -p /run/php /var/www/wordpress \
    && chown -R www-data:www-data /var/www/wordpress

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/
COPY tools/wp-config.sh /wp-config.sh
RUN chmod +x /wp-config.sh

WORKDIR /var/www/wordpress
ENTRYPOINT ["sh", "/wp-config.sh"]