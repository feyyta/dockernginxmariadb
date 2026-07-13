FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl \
	&& openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
		-keyout /etc/nginx/ssl/inception.key \
		-out /etc/nginx/ssl/inception.crt \
		-subj "/C=BE/O=42/CN=mcastrat.42.be"

COPY conf/inception.conf /etc/nginx/conf.d/inception.conf
RUN rm -f /etc/nginx/sites-enabled/default \
	&& rm -rf /var/www/html/*

CMD ["nginx", "-g", "daemon off;"]
