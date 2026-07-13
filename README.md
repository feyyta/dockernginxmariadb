*This project has been created as part of the 42 curriculum by mcastrat.*

# Inception

## Description

Inception is a system administration project. The goal is to set up a small
web infrastructure with docker-compose inside a virtual machine. The whole
stack is built from scratch: no ready-made images, one Dockerfile per
service, all based on debian:bookworm (the penultimate stable version).

The stack is made of three containers:

- **nginx**: the only entry point of the infrastructure. It listens on port
  443 only, with a self-signed TLS certificate (TLSv1.2/1.3), serves the
  static files and forwards PHP requests to WordPress over FastCGI.
- **wordpress**: the website itself, running with php-fpm on port 9000.
  There is no web server in this container. WordPress is downloaded and
  configured automatically with wp-cli on the first start.
- **mariadb**: the database used by WordPress. The database and its users
  are created by an init script on the first start.

The containers communicate through a dedicated Docker network, and the
site files and the database are stored in two volumes located in
`/home/mcastrat/data`, so nothing is lost when the containers are removed
or the machine reboots.

## Instructions

You need Docker, docker-compose and make. The domain `mcastrat.42.be` must
point to the machine, for example with this line in `/etc/hosts`:

```
127.0.0.1 mcastrat.42.be
```

Credentials are not versioned. Before the first run, create a `secrets`
folder at the root of the repository with three files:

- `db_password.txt`: password of the WordPress database user
- `db_root_password.txt`: password of the MariaDB root user
- `credentials.txt`: two lines, the WordPress admin password then the
  password of the second user

Then:

```
make        # build the images and start the stack
make down   # stop the containers
make clean  # stop and remove containers, images and volumes
make fclean # clean + delete the data in /home/mcastrat/data
make re     # full rebuild from scratch
```

The site is then available at https://mcastrat.42.be (the certificate is
self-signed, so the browser shows a warning the first time).

## Design choices

**Virtual machines vs Docker.** A VM emulates a complete machine with its
own kernel, which makes it heavy and slow to boot. A container is just an
isolated process sharing the host kernel, so it starts in seconds and costs
almost nothing. That is why this project can run a whole infrastructure of
three services inside a single VM.

**Secrets vs environment variables.** Environment variables are visible
with a simple `docker inspect`, so they are not a safe place for passwords.
Docker secrets are mounted as files in `/run/secrets`, only inside the
containers that need them. Here the passwords go through secrets, and the
non-sensitive settings (domain name, database name, user names) stay in the
`.env` file.

**Docker network vs host network.** With the host network the containers
would share the network stack of the machine, with no isolation at all
(which is why `network: host` is forbidden by the subject). This project
uses a dedicated bridge network: the containers reach each other by service
name thanks to the internal DNS, and only port 443 of nginx is published to
the outside. MariaDB and php-fpm are unreachable from the host.

**Docker volumes vs bind mounts.** A bind mount maps a host folder directly
into a container, while a named volume is managed by Docker. The subject
requires the data to live in `/home/mcastrat/data`, so I use named volumes
configured with bind options: they are declared and managed in the compose
file like normal volumes, but the data is stored at the required path.

## Problems I ran into

**The volume was never empty.** My MariaDB init script only runs when the
data directory is empty, but it never triggered: when an empty named volume
is mounted for the first time, Docker copies the content of the image into
it, and the Debian package pre-installs a database in `/var/lib/mysql`. So
the volume already contained a database that was not mine. The fix is to
remove that content in the Dockerfile (`rm -rf /var/lib/mysql/*`), and the
same for `/var/www/html` in the nginx image.

**My SQL users were silently ignored.** I create the database and the users
with `mysqld --bootstrap`, and at first nothing I created existed once the
server was up. It turns out the bootstrap mode runs with the grant tables
disabled, so a `FLUSH PRIVILEGES;` is needed at the top of the SQL script
before any `CREATE USER`.
