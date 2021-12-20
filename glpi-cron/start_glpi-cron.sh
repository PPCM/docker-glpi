#!/bin/sh

# Check version of the plugin and update it if needed
# $1 : folder of the plugin
# $2 : required version of the plugin
update_plugin() {
	ACTUAL_VERSION=$(mysql --host=${MYSQL_HOST} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --database=${MYSQL_DATABASE} 2>/dev/null << EOF
SELECT version FROM glpi_plugins WHERE directory LIKE '$1';
EOF
	)
	ACTUAL_VERSION=$(echo ${ACTUAL_VERSION} | cut -d' ' -f2)
	if [ "$2" != "${ACTUAL_VERSION}" ]
	then
		bin/console glpi:plugin:deactivate $1
		cp -a ${HOME}/plugins/$1 plugins
		chown -R apache:apache /var/www/glpi/plugins/$1
		php bin/console glpi:plugin:install -u glpi $1
		php bin/console glpi:plugin:activate $1
	fi
}

# Installation is done. Set the proper file to share the information
install_done() {
	echo "DO NOT REMOVE" >/var/www/glpi/config/.installation_done
}

# Update is needed. Unset the proper file to share the information
update_in_progress() {
	rm /var/www/glpi/config/.installation_done
}

# Check env variables
INSTALL_PARAM=''
if [ -z "${MYSQL_HOST}" ]
then
	echo "MYSQL_HOST must be set"
	exit -1
else
	INSTALL_PARAM="${INSTALL_PARAM} --db-host=${MYSQL_HOST}"
fi
if [ -z "${MYSQL_ROOT_PASSWORD}" ]
then
	echo "MYSQL_ROOT_PASSWORD must be set"
	exit -1
fi
if [ -z "${MYSQL_PORT}" ]
then
	INSTALL_PARAM="${INSTALL_PARAM} --db-port=3306"
else
	INSTALL_PARAM="${INSTALL_PARAM} --db-port=${MYSQL_PORT}"
fi
if [ -z "${MYSQL_DATABASE}" ]
then
	INSTALL_PARAM="${INSTALL_PARAM} --db-name=glpi"
else
	INSTALL_PARAM="${INSTALL_PARAM} --db-name=${MYSQL_DATABASE}"
fi
if [ -z "${MYSQL_USER}" ]
then
	INSTALL_PARAM="${INSTALL_PARAM} --db-user=glpi"
else
	INSTALL_PARAM="${INSTALL_PARAM} --db-user=${MYSQL_USER}"
fi
if [ -z "${MYSQL_PASSWORD}" ]
then
	INSTALL_PARAM="${INSTALL_PARAM} --db-password=glpi-password"
else
	INSTALL_PARAM="${INSTALL_PARAM} --db-password=${MYSQL_PASSWORD}"
fi
if [ -z "${LANG}" ]
then
	INSTALL_PARAM="${INSTALL_PARAM} --default-language=fr_FR"
else
	INSTALL_PARAM="${INSTALL_PARAM} --default-language=${LANG}"
fi
if [ -z "${TZ}" ]
then
	TZ="Europe/Paris"
fi

# Modify default timezone for PHP
sed -i "s|;date.timezone =|date.timezone=${TZ}|" /etc/php7/php.ini

# Do the user and the database exist?
if [ -z "$(mysqlshow --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} | grep ${MYSQL_DATABASE} 2>/dev/null)" ]
then
	# Does the database exist
	if [ -z $(mysqlshow --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=root --password=${MYSQL_ROOT_PASSWORD} | grep ${MYSQL_DATABASE}) ]
	then
		# Creation of the Database
		echo "MySQL Database creation : '${MYSQL_DATABASE}'"
		mysql --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=root --password=${MYSQL_ROOT_PASSWORD} << EOF
CREATE DATABASE ${MYSQL_DATABASE};
EOF
	fi

	# Does the user exist
	if [ -z $(mysql --host=${MYSQL_HOST} --user=root --password=${MYSQL_ROOT_PASSWORD} --database=mysql -e "SELECT User FROM user WHERE User LIKE '${MYSQL_USER}'" | grep ${MYSQL_USER}) ]
	then
		echo "MySQL user creation : ${MYSQL_USER}"
		mysql --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=root --password=${MYSQL_ROOT_PASSWORD} << EOF
CREATE USER '${MYSQL_USER}' IDENTIFIED BY '${MYSQL_PASSWORD}';
EOF
		mysql --host=${MYSQL_HOST} --user=root --password=${MYSQL_ROOT_PASSWORD} --database=mysql -e "SELECT User FROM user WHERE User LIKE '${MYSQL_USER}'"
	fi
fi

if [ -n "${MYSQL_ROOT_PASSWORD}" ]
then
	# Allow GLPI user to access to GLPI database
	mysql --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=root --password=${MYSQL_ROOT_PASSWORD}  << EOF
GRANT ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, EXECUTE, INDEX, INSERT, LOCK TABLES, REFERENCES, SELECT, SHOW VIEW, TRIGGER, UPDATE ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}';
USE mysql;
GRANT SELECT ON mysql.time_zone_name TO '${MYSQL_USER}';
FLUSH PRIVILEGES;
EOF
fi

# Check GLPI actual version
GLPI_ACTUAL_VERSION=$(mysql --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --database=${MYSQL_DATABASE} 2>/dev/null << EOF
SELECT value FROM glpi_configs WHERE name LIKE 'version';
EOF
)
GLPI_ACTUAL_VERSION=$(echo ${GLPI_ACTUAL_VERSION} | cut -d' ' -f2)

echo "Current version :" ${GLPI_ACTUAL_VERSION}
echo "Docker version :" ${GLPI_VERSION}

# Set the working directory
cd /var/www/glpi

if [ -z "${GLPI_ACTUAL_VERSION}" ]
then
	# Install GLPI
	echo "GLPI installation"
	bin/console -n db:install ${INSTALL_PARAM}

	# Copy all plugins to GLPI folder
	mv plugins/* /var/www/glpi/plugins

	# Install plugins
	echo "Plugins installation"
	php bin/console glpi:plugin:install -u glpi --all
	php bin/console glpi:plugin:activate --all

	# Installation done
	install_done

	# Set the Apache as owner of all files and directories
	chown -R apache:apache /var/www/glpi
else
	# Check GLPI version
	if [ "${GLPI_VERSION}" != "${GLPI_ACTUAL_VERSION}" ]
	then
		# Update GLPI
		echo "GLPI update"

		# The update must start
		update_in_progress

		# Launch the update
		bin/console -n db:update

		# Reactivaye all plugins
		echo "Plugins activation"
		php bin/console glpi:plugin:activate --all

		# Update done
		install_done

		# Set the Apache as owner of all files and directories
		chown -R apache:apache /var/www/glpi

	fi
fi

# Check plugins version
# Accounts plugin
update_plugin "accounts" "${PLUGIN_ACCOUNT_VERSION}"

# Addressing plugin
update_plugin "addressing" "${PLUGIN_ADDRESSING_VERSION}"

# Fields plugin
update_plugin "fields" "${PLUGIN_FIELDS_VERSION}"

# FusionInventory plugin
update_plugin "fusioninventory" "${PLUGIN_FUSIONINVENTORY_VERSION}"

# Manage Entities plugin
update_plugin "manageentities" "${PLUGIN_MANAGEENTITIES_VERSION}"

# Manufacturers Imports plugin
update_plugin "manufacturersimports" "${PLUGIN_MANUFACTURESIMPORTS_VERSION}"

# MReports plugin
update_plugin "mreporting" "${PLUGIN_MREPORTING_VERSION}"

# News plugin
update_plugin "news" "${PLUGIN_NEWS_VERSION}"

# Reports plugin
update_plugin "reports" "${PLUGIN_REPORTS_VERSION}"

# Remove glpi install directory
rm -rf /var/www/glpi/install

# Remove plugins temp directory
rm -rf ${HOME}/plugins

# Run crond for crontabs/apache
/usr/sbin/crond -f
