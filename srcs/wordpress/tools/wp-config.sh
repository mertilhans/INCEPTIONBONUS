#!/bin/sh

WP="wp --path=/var/www/wordpress --allow-root"

if [ ! -f /var/www/wordpress/wp-config.php ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

    $WP core download

    $WP config create --dbname=${DB_NAME} --dbuser=${DB_USER} \
                      --dbpass=${DB_PASSWORD} --dbhost=mariadb --skip-check

    until $WP core install --url=https://${DOMAIN_NAME} --title="${WP_TITTLE}" \
                           --admin_user=${WP_ADMIN_USER} --admin_password=${WP_ADMIN_PASSWORD} \
                           --admin_email=${WP_ADMIN_EMAIL} --skip-email; do
        sleep 2
    done

    $WP user create ${WP_USER} ${WP_USER_EMAIL} --user_pass=${WP_USER_PASSWORD} --role=author

    $WP config set WP_REDIS_HOST redis
    $WP config set WP_REDIS_PORT 6379
    $WP plugin install redis-cache --activate
    $WP redis enable
fi

chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress

mkdir -p /run/php
exec php-fpm8.2 -F
