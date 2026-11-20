#!/bin/sh
set -e

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ -z "$MARIADB_USER" ]; then
    echo "Error: MARIADB_USER is empty"
    exit 1
fi

if [ -z "$MARIADB_DATABASE" ]; then
    echo "Error: MARIADB_DATABASE is empty"
    exit 1
fi

if [ ! -s /run/secrets/db_root_password ]; then
    echo "Error: db_root_password is empty"
    exit 1
fi

if [ ! -s /run/secrets/db_password ]; then
    echo "Error: db_password is empty"
    exit 1
fi


if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db
fi

if [ ! -d /var/lib/mysql/$MARIADB_DATABASE ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    mariadbd --user=mysql --bootstrap <<EOF
    FLUSH PRIVILEGES;
    CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${MARIADB_DATABASE}.* TO '${MARIADB_USER}'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};
EOF
fi 

exec mariadbd --user=mysql
