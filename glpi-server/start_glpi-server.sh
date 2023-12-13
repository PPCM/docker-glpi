#!/bin/sh

# Run a GLPI console command
# $1 : Command to run
glpi_console() {
	# We want this to output "${@}" without expansion
	# shellcheck disable=SC2016
	cd '/var/www/glpi' &&
		su 'apache' -s '/bin/ash' -c '"${@}"' -- '/usr/bin/php' '/var/www/glpi/bin/console' "${@}"
}


# Check version of the plugin and update it if needed
# $1 : folder of the plugin
# $2 : required version of the plugin
update_plugin() {
	ACTUAL_VERSION=$(mysql --host="${MYSQL_HOST}" --user="${MYSQL_USER}" --password="${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" 2>/dev/null << EOF
SELECT version FROM glpi_plugins WHERE directory LIKE '$1';
EOF
	)
	ACTUAL_VERSION="$(echo "${ACTUAL_VERSION}" | cut -d' ' -f2)"
	if [ "$2" != "${ACTUAL_VERSION}" ]
	then
		echo "Update plugin : $1"
		glpi_console 'glpi:plugin:deactivate' "$1"
		cp -a "${HOME}/plugins/$1" '/var/www/glpi/plugins'
		glpi_console 'glpi:plugin:install' -u 'glpi' "$1"
		glpi_console 'glpi:plugin:activate' "$1"
	fi
}

# Installation is done. Set the proper file to share the information
install_done() {
	echo "DO NOT REMOVE" >'/etc/glpi/.installation_done'
}

# Update is needed. Unset the proper file to share the information
update_in_progress() {
	rm '/etc/glpi/.installation_done'
}

# Check env variables
if [ -z "${MYSQL_HOST}" ]
then
	echo "MYSQL_HOST must be set"
	exit 1
fi
if [ -z "${MYSQL_ROOT_PASSWORD}" ]
then
	echo "MYSQL_ROOT_PASSWORD must be set"
	exit 1
fi
if [ -z "${MYSQL_PORT}" ]
then
	MYSQL_PORT="3306"
fi
if [ -z "${MYSQL_DATABASE}" ]
then
	MYSQL_DATABASE="glpi"
fi
if [ -z "${MYSQL_USER}" ]
then
	MYSQL_USER="glpi"
fi
if [ -z "${MYSQL_PASSWORD}" ]
then
	MYSQL_PASSWORD="glpi-password"
fi
if [ -z "${LANG}" ]
then
	LANG="fr_FR"
fi
if [ -z "${TZ}" ]
then
	TZ="Europe/Paris"
fi

# Modify default timezone for PHP
sed -i "s|;date.timezone =|date.timezone=${TZ}|" /etc/php81/php.ini

# Modify default cookie_httponly value for security purpose
sed -i "s|session.cookie_httponly =|session.cookie_httponly = 1|" /etc/php81/php.ini

# Modify maximum amount of memory a script may consume
sed -i "s|memory_limit = 128M|memory_limit = 256M|" /etc/php81/php.ini

# Modify maximum execution time of each script, in seconds
sed -i "s|max_execution_time = 30|max_execution_time = 600|" /etc/php81/php.ini

# Do the user and the database exist?
if [ -z "$(mysqlshow --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user="${MYSQL_USER}" --password="${MYSQL_PASSWORD}" | grep "${MYSQL_DATABASE}" 2>/dev/null)" ]
then
	# Does the database exist
	if [ -z "$(mysqlshow --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user=root --password="${MYSQL_ROOT_PASSWORD}" | grep "${MYSQL_DATABASE}")" ]
	then
		# Creation of the Database
		echo "MySQL Database creation : '${MYSQL_DATABASE}'"
		mysql --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user=root --password="${MYSQL_ROOT_PASSWORD}" << EOF
CREATE DATABASE \`${MYSQL_DATABASE}\`;
EOF
	fi

	# Does the user exist
	if [ -z "$(mysql --host="${MYSQL_HOST}" --user=root --password="${MYSQL_ROOT_PASSWORD}" --database=mysql -e "SELECT User FROM user WHERE User LIKE '${MYSQL_USER}'" | grep "${MYSQL_USER}")" ]
	then
		echo "MySQL user creation : ${MYSQL_USER}"
		mysql --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user=root --password="${MYSQL_ROOT_PASSWORD}" << EOF
CREATE USER '${MYSQL_USER}' IDENTIFIED BY '${MYSQL_PASSWORD}';
EOF
		mysql --host="${MYSQL_HOST}" --user=root --password="${MYSQL_ROOT_PASSWORD}" --database=mysql -e "SELECT User FROM user WHERE User LIKE '${MYSQL_USER}'"
	fi
fi

if [ -n "${MYSQL_ROOT_PASSWORD}" ]
then
	# Allow GLPI user to access to GLPI database
	mysql --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user=root --password="${MYSQL_ROOT_PASSWORD}"	<< EOF
GRANT ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, EXECUTE, INDEX, INSERT, LOCK TABLES, REFERENCES, SELECT, SHOW VIEW, TRIGGER, UPDATE ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}';
USE mysql;
GRANT SELECT ON mysql.time_zone_name TO '${MYSQL_USER}';
FLUSH PRIVILEGES;
EOF
fi

# Check GLPI actual version
GLPI_ACTUAL_VERSION="$(mysql --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user="${MYSQL_USER}" --password="${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" 2>/dev/null << EOF
SELECT value FROM glpi_configs WHERE name LIKE 'version';
EOF
)"
GLPI_ACTUAL_VERSION="$(echo "${GLPI_ACTUAL_VERSION}" | cut -d' ' -f2)"

echo "Current version : ${GLPI_ACTUAL_VERSION}"
echo "Docker version : ${GLPI_VERSION}"

if [ -z "${GLPI_ACTUAL_VERSION}" ]
then
	# Install GLPI
	echo "GLPI installation"
	cp -a '/root/config/'* '/etc/glpi'
	cp -a '/root/files' '/var/glpi'
	cp -a '/root/plugins' '/var/www/glpi'
	cp -a '/root/marketplace' '/var/www/glpi'
	glpi_console -n 'db:install' --db-host="${MYSQL_HOST}" --db-port="${MYSQL_PORT}" --db-name="${MYSQL_DATABASE}" --db-user="${MYSQL_USER}" --db-password="${MYSQL_PASSWORD}" --default-language="${LANG}"

	# Install plugins
	echo "Plugins installation"
	glpi_console 'glpi:plugin:install' -u 'glpi' --all
	glpi_console 'glpi:plugin:activate' --all

	# Set the Apache as owner of all files and directories
	#chown -R apache:apache /var/www/glpi

	# Installation done
	install_done
else

	# Check if local_define.php is present, correct previous versions of container
	if [ ! -f "/etc/glpi/local_define.php" ]
		then
			echo "Correct local_define.php file"
			cp -a config/local_define.php /etc/glpi
	fi

	# Check GLPI version
	if [ "${GLPI_VERSION}" != "${GLPI_ACTUAL_VERSION}" ]
	then
		# Update GLPI
		echo "GLPI update"

		# The update must start
		update_in_progress

		# Launch the update
		glpi_console -n 'db:update'

		# Reactivate all plugins
		echo "Plugins activation"
		glpi_console 'glpi:plugin:activate' --all

		# Set the Apache as owner of all files and directories
		#chown -R apache:apache /var/www/glpi

		# Update done
		install_done
	fi
fi

# Check plugins version
# Accounts plugin
update_plugin "accounts" "${PLUGIN_ACCOUNT_VERSION}"

# Fields plugin
update_plugin "fields" "${PLUGIN_FIELDS_VERSION}"

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
#rm -rf ${HOME}/plugins

# Set the Apache as owner of all files and directories
#chown -R apache:apache /var/www/glpi
#chown -R apache:apache /var/glpi

# Launch Apache2 as Apache user
#su apache -s /bin/ash -c "/usr/sbin/httpd -D FOREGROUND"
/usr/sbin/httpd -D FOREGROUND
