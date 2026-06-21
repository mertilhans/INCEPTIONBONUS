#!/bin/sh
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    
    cat << EOF > /tmp/i.sql
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    mysqld --user=mysql --bootstrap < /tmp/i.sql
fi

exec mysqld --user=mysql --bind-address=0.0.0.0