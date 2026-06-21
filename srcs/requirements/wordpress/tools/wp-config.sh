#!/bin/sh

# Veritabanının hazır olması için bekle
sleep 20

if [ ! -f /var/www/wordpress/wp-config.php ]; then
    wp core download --allow-root --path=/var/www/wordpress
    
    wp config create --dbname=${DB_NAME} \
                     --dbuser=${DB_USER} \
                     --dbpass=${DB_PASSWORD} \
                     --dbhost=mariadb \
                     --path=/var/www/wordpress \
                     --allow-root

    wp core install --url=${DOMAIN_NAME} \
                    --title="${WP_TITTLE}" \
                    --admin_user=${WP_ADMIN_USER} \
                    --admin_password=${WP_ADMIN_PASSWORD} \
                    --admin_email=${WP_ADMIN_EMAIL} \
                    --path=/var/www/wordpress \
                    --allow-root
fi

chown -R www-data:www-data /var/www/wordpress
chmod -R 777 /var/www/wordpress

mkdir -p /run/php
exec php-fpm8.2 -F