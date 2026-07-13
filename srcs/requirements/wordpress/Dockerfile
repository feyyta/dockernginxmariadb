FROM debian:bookworm

RUN apt-get update && apt-get install -y \
		php8.2-fpm \
		php8.2-mysql \
		php8.2-curl \
		mariadb-client \
		curl \
		ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp \
		https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

ENTRYPOINT ["setup.sh"]
