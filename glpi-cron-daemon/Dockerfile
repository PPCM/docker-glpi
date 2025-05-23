# syntax=docker/dockerfile:1

# Dockerfile for GLPI cron
# Compile : docker build --no-cache -t ppcm/glpi-cron-daemon .
# Build multiplateform : docker buildx build --no-cache --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-cron:latest .

#ENV CRON_SCHEDULE - Schedule in CRON format - [cron.guru](https://crontab.guru/) can help you to define it - By default the value is "*/2 * * * *"
#ENV TZ - specify a timezone to use, see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)

# VOLUME glpi-config - Persistence for GLPI Config
# VOLUME glpi-files - Persistence for GLPI stored files
# VOLUME glpi-plugins - Persistence for GLPI installed plugins
# VOLUME glpi-marketplace - Persistence for GLPI installed plugins by the marketplace

FROM alpine:3.19.1

ENV NODE_ENV=production

# Variables for versions
ENV GLPI_VERSION="10.0.18"
ENV CAS_VERSION="1.6.1"

RUN apk --no-cache upgrade \
    && apk add --no-cache \
		          php83 \
						  php83-curl php83-fileinfo php83-gd php83-mbstring php83-mysqli php83-session \
						  php83-simplexml php83-xml php83-xmlreader php83-xmlwriter php83-intl php83-dom php83-soap \
						  php83-ldap php83-pecl-apcu php83-ctype php83-sodium php83-snmp \
						  php83-exif php83-phar php83-zip php83-bz2 php83-opcache php83-iconv php83-pdo \
						  nmap perl perl-net-snmp perl-crypt-des perl-digest-hmac wget inotify-tools tzdata

# Working directory to root
WORKDIR /root

# Installation GLPI
RUN \
	# Create Apache user and needed folders
	mkdir -p /var/www/glpi \
	&& addgroup -g 101 apache \
	&& adduser -u 100 -H -D -h /var/www -s /sbin/nologin -G apache -g 'apache' apache \
	# Installation of GLPI
	&& wget https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz \
  && tar xzf glpi-${GLPI_VERSION}.tgz \
	&& mv glpi /var/www/ \
	&& mv /var/www/glpi/config . \
	&& mv /var/www/glpi/files . \
	&& mv /var/www/glpi/plugins . \
	&& mv /var/www/glpi/marketplace . \
	&& mkdir -p /etc/glpi \
	&& mkdir -p /var/glpi/files \
	&& mkdir -p /var/www/glpi/plugins \
	&& mkdir -p /var/www/glpi/marketplace \
	&& rm glpi-${GLPI_VERSION}.tgz

# Copy specific config file
COPY downstream.php /var/www/glpi/inc
RUN chmod a-x /var/www/glpi/inc/downstream.php

# Change the Owner of folders
RUN \
	chown -R apache:apache /var/www/glpi \
	&& chown -R apache:apache /etc/glpi \
	&& chown -R apache:apache /var/glpi \
	&& chown -R apache:apache files \
	&& chown -R apache:apache plugins \
	&& chown -R apache:apache marketplace

# GLPI cron start script and cron config
COPY start_glpi-cron-daemon.sh .
COPY glpi.cron /etc/crontabs/root
RUN chmod go-rwx /etc/crontabs/root \
	&& chmod u-x /etc/crontabs/root \
	&& chmod a+x start_glpi-cron-daemon.sh

# Mount volumes persistence
VOLUME /etc/glpi
VOLUME /var/glpi/files
VOLUME /var/www/glpi/plugins
VOLUME /var/www/glpi/marketplace

# Run Start script
ENTRYPOINT ["/root/start_glpi-cron-daemon.sh"]
