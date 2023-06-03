# syntax=docker/dockerfile:1

# Dockerfile for GLPI cron
# Compile : docker build --no-cache -t ppcm/glpi-cron .
# Build multiplateform : docker buildx build --no-cache --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-cron:latest .

#ENV CRON_SCHEDULE - Schedule in CRON format - [cron.guru](https://crontab.guru/) can help you to define it - By default the value is "*/2 * * * *"
#ENV TZ - specify a timezone to use, see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)

# VOLUME glpi-config - Persistence for GLPI Config
# VOLUME glpi-files - Persistence for GLPI stored files
# VOLUME glpi-plugins - Persistence for GLPI installed plugins
# VOLUME glpi-marketplace - Persistence for GLPI installed plugins by the marketplace

FROM alpine:3.17

ENV NODE_ENV=production

# Variables for versions
ENV GLPI_VERSION="10.0.7"
ENV CAS_VERSION="1.6.1"

RUN apk --no-cache upgrade \
    && apk add --no-cache \
							php81 \
						  php81-curl php81-fileinfo php81-gd php81-mbstring php81-mysqli php81-session \
						  php81-simplexml php81-xml php81-intl php81-dom php81-soap \
						  php81-ldap php81-pecl-apcu php81-ctype php81-sodium php81-snmp \
						  php81-exif php81-phar php81-zip php81-bz2 php81-opcache php81-pear php81-iconv php81-pdo \
						  nmap perl perl-net-snmp perl-crypt-des perl-digest-hmac wget inotify-tools


# Working directory to root
WORKDIR /root

# Installation GLPI
RUN \
	# Create Apache user and needed folders
	mkdir -p /var/www/glpi \
	&& addgroup -g 101 apache \
	&& adduser -u 100 -H -D -h /var/www -s /sbin/nologin -G apache -g 'apache' apache \
	# Installation of phpCAS
	&& wget https://github.com/apereo/phpCAS/releases/download/${CAS_VERSION}/CAS-${CAS_VERSION}.tgz \
	&& pear install CAS-${CAS_VERSION}.tgz \
	&& rm CAS-${CAS_VERSION}.tgz \
	# Installation of GLPI
	&& wget https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz \
  && tar xzf glpi-${GLPI_VERSION}.tgz \
	&& mv glpi /var/www/ \
	&& mv /var/www/glpi/config . \
	&& mv /var/www/glpi/files . \
	&& mv /var/www/glpi/plugins . \
	&& mv /var/www/glpi/marketplace . \
	&& mkdir -p /var/glpi/config \
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
	&& chown -R apache:apache /var/glpi \
	&& chown -R apache:apache files \
	&& chown -R apache:apache plugins \
	&& chown -R apache:apache marketplace

# GLPI cron start script and cron config
COPY start_glpi-cron-daemon.sh .
COPY glpi.cron /etc/crontabs/glpi.cron
RUN chmod go-rwx /etc/crontabs/glpi.cron \
	&& chmod u-x /etc/crontabs/glpi.cron \
	&& chmod a+x start_glpi-cron-daemon.sh

# Mount volumes persistence
VOLUME /etc/glpi
VOLUME /var/glpi/files
VOLUME /var/www/glpi/plugins
VOLUME /var/www/glpi/marketplace

# Run Start script
ENTRYPOINT ["/root/start_glpi-cron-daemon.sh"]
