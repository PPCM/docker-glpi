# syntax=docker/dockerfile:1

# Dockerfile for GLPI
# Compile : docker build --no-cache -t ppcm/glpi-server .
# Build multiplateform : docker buildx build --no-cache --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-server:latest .

#ENV MYSQL_HOST : address/host name of the MySQL server
#ENV MYSQL_PORT : define port of the MySQL server
#ENV MYSQL_ROOT_PASSWORD : MySQL root password
#ENV MYSQL_USER : MySQL user to use for GLPI
#ENV MYSQL_PASSWORD : Password to use for MySQL user for GLPI
#ENV LANG : Language to use for GLPI UI
#ENV TZ - specify a timezone to use, see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)

# VOLUME glpi-config - Persistence for GLPI Config
# VOLUME glpi-files - Persistence for GLPI stored files
# VOLUME glpi-plugins - Persistence for GLPI installed plugins
# VOLUME glpi-marketplace - Persistence for GLPI installed plugins by the marketplace

FROM alpine:3.20

ENV NODE_ENV=production

# Variables for versions
ENV GLPI_VERSION="10.0.18"
ENV CAS_VERSION="1.6.1"
ENV PLUGIN_ACCOUNT_VERSION="3.0.4"
ENV PLUGIN_FIELDS_VERSION="1.21.21"
ENV PLUGIN_MANAGEENTITIES_VERSION="4.0.3"
ENV PLUGIN_MANUFACTURESIMPORTS_VERSION="3.0.9"
ENV PLUGIN_MREPORTING_VERSION="1.8.7"
ENV PLUGIN_NEWS_VERSION="1.12.4"
ENV PLUGIN_REPORTS_VERSION="1.16.0"
ENV PLUGIN_GLPIINVENTORY_VERSION="1.5.0"

RUN apk --no-cache upgrade \
    && apk add --no-cache \
							mariadb-client \
		          apache2 php83-apache2 php83 \
						  php83-curl php83-fileinfo php83-gd php83-mbstring php83-mysqli php83-session \
						  php83-simplexml php83-xml php83-xmlreader php83-xmlwriter php83-intl php83-dom php83-soap \
						  php83-ldap php83-pecl-apcu php83-ctype php83-sodium php83-snmp \
						  php83-exif php83-phar php83-zip php83-bz2 php83-opcache php83-pear php83-iconv php83-pdo \
						  nmap perl perl-net-snmp perl-crypt-des perl-digest-hmac wget inotify-tools tzdata

# Working directory to root
WORKDIR /root

# Configure Apache2
COPY httpd.conf /etc/apache2

# Installation phpCAS, GLPI & plugins
RUN \
	# Installation of phpCAS
	wget https://github.com/apereo/phpCAS/releases/download/${CAS_VERSION}/CAS-${CAS_VERSION}.tgz \
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
	&& mkdir -p /etc/glpi \
	&& mkdir -p /var/glpi/files \
	&& mkdir -p /var/www/glpi/plugins \
	&& mkdir -p /var/www/glpi/marketplace \
	&& rm glpi-${GLPI_VERSION}.tgz \
	&& cd plugins \
	# Installation of the plugin accounts
	&& wget https://github.com/InfotelGLPI/accounts/releases/download/${PLUGIN_ACCOUNT_VERSION}/glpi-accounts-${PLUGIN_ACCOUNT_VERSION}.tar.bz2 \
	&& tar xjf glpi-accounts-${PLUGIN_ACCOUNT_VERSION}.tar.bz2 \
	&& rm glpi-accounts-${PLUGIN_ACCOUNT_VERSION}.tar.bz2 \
	# Installation of the plugin Fields GLPI plugin
	&& wget https://github.com/pluginsGLPI/fields/releases/download/${PLUGIN_FIELDS_VERSION}/glpi-fields-${PLUGIN_FIELDS_VERSION}.tar.bz2 \
	&& tar xjf glpi-fields-${PLUGIN_FIELDS_VERSION}.tar.bz2 \
	&& rm glpi-fields-${PLUGIN_FIELDS_VERSION}.tar.bz2 \
	# Installation of the plugin manageentities
	&& wget https://github.com/InfotelGLPI/manageentities/releases/download/${PLUGIN_MANAGEENTITIES_VERSION}/glpi-manageentities-${PLUGIN_MANAGEENTITIES_VERSION}.tar.bz2 \
	&& tar xjf glpi-manageentities-${PLUGIN_MANAGEENTITIES_VERSION}.tar.bz2 \
	&& rm glpi-manageentities-${PLUGIN_MANAGEENTITIES_VERSION}.tar.bz2 \
	# Installation of the plugin manufacturersimports
	&& wget https://github.com/InfotelGLPI/manufacturersimports/releases/download/${PLUGIN_MANUFACTURESIMPORTS_VERSION}/glpi-manufacturersimports-${PLUGIN_MANUFACTURESIMPORTS_VERSION}.tar.bz2 \
	&& tar xjf glpi-manufacturersimports-${PLUGIN_MANUFACTURESIMPORTS_VERSION}.tar.bz2 \
	&& rm glpi-manufacturersimports-${PLUGIN_MANUFACTURESIMPORTS_VERSION}.tar.bz2 \
	# Installation of the plugin More reporting
	&& wget https://github.com/pluginsGLPI/mreporting/releases/download/${PLUGIN_MREPORTING_VERSION}/glpi-mreporting-${PLUGIN_MREPORTING_VERSION}.tar.bz2 \
	&& tar xjf glpi-mreporting-${PLUGIN_MREPORTING_VERSION}.tar.bz2 \
	&& rm glpi-mreporting-${PLUGIN_MREPORTING_VERSION}.tar.bz2 \
	# Installation of the plugin News
	&& wget https://github.com/pluginsGLPI/news/releases/download/${PLUGIN_NEWS_VERSION}/glpi-news-${PLUGIN_NEWS_VERSION}.tar.bz2 \
	&& tar xjf glpi-news-${PLUGIN_NEWS_VERSION}.tar.bz2 \
	&& rm glpi-news-${PLUGIN_NEWS_VERSION}.tar.bz2 \
	# Installation of the plugin Additional reports
	&& wget https://github.com/yllen/reports/releases/download/v${PLUGIN_REPORTS_VERSION}/glpi-reports-${PLUGIN_REPORTS_VERSION}.tar.gz \
	&& tar xzf glpi-reports-${PLUGIN_REPORTS_VERSION}.tar.gz \
	&& rm glpi-reports-${PLUGIN_REPORTS_VERSION}.tar.gz \
	# Installation of the plugin GLPI Inventory
	&& wget https://github.com/glpi-project/glpi-inventory-plugin/releases/download/${PLUGIN_GLPIINVENTORY_VERSION}/glpi-glpiinventory-${PLUGIN_GLPIINVENTORY_VERSION}.tar.bz2 \
	&& tar xjf glpi-glpiinventory-${PLUGIN_GLPIINVENTORY_VERSION}.tar.bz2 \
	&& rm glpi-glpiinventory-${PLUGIN_GLPIINVENTORY_VERSION}.tar.bz2

# Copy specific config file
COPY downstream.php /var/www/glpi/inc
RUN chmod a-x /var/www/glpi/inc/downstream.php

# Copy specific config file
COPY local_define.php config
RUN chmod a-x config/local_define.php

# Change the Owner of folders
RUN \
	chown -R apache:apache /var/www/glpi \
	&& chown -R apache:apache /etc/glpi \
	&& chown -R apache:apache /var/glpi \
	&& chown -R apache:apache files \
	&& chown -R apache:apache plugins \
	&& chown -R apache:apache marketplace

# GLPI start script
COPY start_glpi-server.sh /root
RUN chmod a+x /root/start_glpi-server.sh

# Open port for httpd access
EXPOSE 80

# Mount volumes persistence
VOLUME /etc/glpi
VOLUME /var/glpi/files
VOLUME /var/www/glpi/plugins
VOLUME /var/www/glpi/marketplace

# Run Start script
ENTRYPOINT ["/root/start_glpi-server.sh"]
