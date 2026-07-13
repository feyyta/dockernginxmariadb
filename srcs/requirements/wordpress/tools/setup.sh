#!/bin/sh

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(sed -n '1p' /run/secrets/credentials)
WP_USER_PASSWORD=$(sed -n '2p' /run/secrets/credentials)

tries=0
until mariadb -h mariadb -u "$MYSQL_USER" -p"$DB_PASSWORD" "$MYSQL_DATABASE" -e "SELECT 1" > /dev/null 2>&1
do
	tries=$((tries + 1))
	if [ "$tries" -gt 30 ]; then
		echo "mariadb unreachable"
		exit 1
	fi
	sleep 2
done

if [ ! -f wp-config.php ]; then
	wp core download --allow-root

	wp config create --allow-root \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
		--dbpass="$DB_PASSWORD" \
		--dbhost=mariadb:3306

	wp core install --allow-root \
		--url="https://$DOMAIN_NAME" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email

	wp user create --allow-root \
		"$WP_USER" "$WP_USER_EMAIL" \
		--role=author \
		--user_pass="$WP_USER_PASSWORD"

	chown -R www-data:www-data /var/www/html
fi

mkdir -p /run/php
exec php-fpm8.2 -F
