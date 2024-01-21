#!/bin/ash

# Run a GLPI console command
# $1 : Command to run
glpi_console() {
	su - 'apache' -s '/bin/ash' -c "cd '/var/www/glpi' && bin/console ${*}"
}

# Check version of the plugin and update it if needed
# $1 : folder of the plugin
# $2 : required version of the plugin
update_plugin() {
	ACTUAL_VERSION=$(mysql --host="${MYSQL_HOST}" --user="${MYSQL_USER}" --password="${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" 2>/dev/null << EOF
SELECT version FROM glpi_plugins WHERE directory LIKE '$1';
EOF
	)
	ACTUAL_VERSION=$(echo ${ACTUAL_VERSION} | cut -d' ' -f2)
	if [ "$2" != "${ACTUAL_VERSION}" ]
	then
		echo "Update plugin : " $1
		[ ! -d "/var/www/glpi/plugins/$1" ] || glpi_console 'glpi:plugin:deactivate' "'""$1""'"
		cp -a "${HOME}/plugins/$1" '/var/www/glpi/plugins'
		glpi_console 'glpi:plugin:install' -u 'glpi' "'""$1""'"
	fi
	glpi_console 'glpi:plugin:activate' "'""$1""'"
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
## MYSQL_ROOT_PASSWORD is no more mandatory
if [ -z "${MYSQL_HOST}" ]
then
	echo 'MYSQL_HOST must be set'
	exit 1
fi
if [ -z "${MYSQL_PORT}" ]
then
    MYSQL_PORT='3306'
fi
if [ -z "${MYSQL_DATABASE}" ]
then
    MYSQL_DATABASE='glpi'
fi
if [ -z "${MYSQL_USER}" ]
then
    MYSQL_USER='glpi'
fi
if [ -z "${MYSQL_PASSWORD}" ]
then
    MYSQL_PASSWORD='glpi-password'
fi
if [ -z "${LANG}" ]
then
    LANG='fr_FR'
fi
if [ -z "${TZ}" ]
then
	TZ='Europe/Paris'
fi
if [ -z "${PLUGIN_ACCOUNT_ACTIVE}" ]
then
	PLUGIN_ACCOUNT_ACTIVE=1
fi
if [ -z "${PLUGIN_FIELDS_ACTIVE}" ]
then
	PLUGIN_FIELDS_ACTIVE=1
fi
if [ -z "${PLUGIN_MANAGEENTITIES_ACTIVE}" ]
then
	PLUGIN_MANAGEENTITIES_ACTIVE=1
fi
if [ -z "${PLUGIN_MANUFACTURESIMPORTS_ACTIVE}" ]
then
	PLUGIN_MANUFACTURESIMPORTS_ACTIVE=1
fi
if [ -z "${PLUGIN_MREPORTING_ACTIVE}" ]
then
	PLUGIN_MREPORTING_ACTIVE=1
fi
if [ -z "${PLUGIN_NEWS_ACTIVE}" ]
then
	PLUGIN_NEWS_ACTIVE=1
fi
if [ -z "${PLUGIN_REPORTS_ACTIVE}" ]
then
	PLUGIN_REPORTS_ACTIVE=1
fi

# Modify default timezone for PHP
sed -i "s|;date.timezone =|date.timezone=${TZ}|" /etc/php82/php.ini

# Modify default cookie_httponly value for security purpose
sed -i "s|session.cookie_httponly =|session.cookie_httponly = 1|" /etc/php82/php.ini

# Modify maximum amount of memory a script may consume
sed -i "s|memory_limit = 128M|memory_limit = 256M|" /etc/php82/php.ini

# Modify maximum execution time of each script, in seconds
sed -i "s|max_execution_time = 30|max_execution_time = 600|" /etc/php82/php.ini

# Does the GLPI database config file exists
if [ ! -f '/etc/glpi/config_db.php' ]
then
	echo 'Config file does not exist'

	# Do the user and the database exist?
	if [ -z "$(mysqlshow --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user="${MYSQL_USER}" --password="${MYSQL_PASSWORD}" | grep "${MYSQL_DATABASE}" 2>/dev/null)" ]
	then

		# Check  if MYSQL_ROOT_PASSWORD exists
		if [ -z "${MYSQL_ROOT_PASSWORD}" ]
		then
			echo 'GLPI user or/and GLPI database doesn'"'"'t exists, MYSQL_ROOT_PASSWORD must be set'
			exit 1
		fi

		# Does the database exist
		if [ -z "$(mysqlshow --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user=root --password="${MYSQL_ROOT_PASSWORD}" | grep "${MYSQL_DATABASE}")" ]
		then
			# Creation of the Database
			echo "MySQL Database creation : '${MYSQL_DATABASE}'"
			mysql --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user=root --password="${MYSQL_ROOT_PASSWORD}" << EOF
CREATE DATABASE ${MYSQL_DATABASE};
EOF
		fi

		# Does the user exist
		if [ -z "$(mysql --host="${MYSQL_HOST}" --user=root --password="${MYSQL_ROOT_PASSWORD}" --database=mysql -e "SELECT User FROM user WHERE User LIKE '${MYSQL_USER}'" | grep "${MYSQL_USER}")" ]
		then
			echo "MySQL user creation : ${MYSQL_USER}"
			mysql --host=${MYSQL_HOST} --port=${MYSQL_PORT} --user=root --password=${MYSQL_ROOT_PASSWORD} << EOF
CREATE USER '${MYSQL_USER}' IDENTIFIED BY '${MYSQL_PASSWORD}';
EOF
		fi
	fi

	# Allow GLPI user to access to GLPI database only if MYSQL_ROOT_PASSWORD is set
	if [ -n "${MYSQL_ROOT_PASSWORD}" ]
	then
		echo "MySQL grant user : ${MYSQL_USER}"
		mysql --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user=root --password="${MYSQL_ROOT_PASSWORD}"  << EOF
GRANT ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, EXECUTE, INDEX, INSERT, LOCK TABLES, REFERENCES, SELECT, SHOW VIEW, TRIGGER, UPDATE ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}';
USE mysql;
GRANT SELECT ON mysql.time_zone_name TO '${MYSQL_USER}';
FLUSH PRIVILEGES;
EOF
	fi
fi

# Check GLPI actual version
GLPI_ACTUAL_VERSION="$(mysql --host="${MYSQL_HOST}" --port="${MYSQL_PORT}" --user="${MYSQL_USER}" --password="${MYSQL_PASSWORD}" --database="${MYSQL_DATABASE}" 2>/dev/null << EOF
SELECT value FROM glpi_configs WHERE name LIKE 'version';
EOF
)"
GLPI_ACTUAL_VERSION="$(echo ${GLPI_ACTUAL_VERSION} | cut -d' ' -f2)"

echo "Current version : ${GLPI_ACTUAL_VERSION}"
echo "Docker version : ${GLPI_VERSION}"

if [ -z "${GLPI_ACTUAL_VERSION}" ]
then
	# Install GLPI
	echo "GLPI installation"
	cp -a -- /root/config/* /etc/glpi
	cp -a /root/files /var/glpi
	#cp -a /root/plugins /var/www/glpi
	mkdir -p /var/www/glpi/plugins
	cp -a /root/marketplace /var/www/glpi
	glpi_console -n 'db:install' --db-host="'""${MYSQL_HOST}""'" --db-port="'""${MYSQL_PORT}""'" --db-name="'""${MYSQL_DATABASE}""'" --db-user="'""${MYSQL_USER}""'" --db-password="'""${MYSQL_PASSWORD}""'" --default-language="'""${LANG}""'"

	# Installation done
	install_done
else

	# Check if local_define.php is present, correct previous versions of container
	if [ ! -f '/etc/glpi/local_define.php' ]
		then
			echo 'Correct local_define.php file'
			cp -a 'config/local_define.php /etc/glpi'
	fi

	# Check GLPI version
	if [ "${GLPI_VERSION}" != "${GLPI_ACTUAL_VERSION}" ]
	then
		# Update GLPI
		echo 'GLPI update'

		# The update must start
		update_in_progress

		# Launch the update
		glpi_console -n 'db:update'

		# Update done
		install_done
	fi
fi

# Check plugins version
# Accounts plugin
if [ -n "${PLUGIN_ACCOUNT_ACTIVE}" ] && [ "${PLUGIN_ACCOUNT_ACTIVE}" != "0" ]
then
	update_plugin 'accounts' "${PLUGIN_ACCOUNT_VERSION}"
fi

# Fields plugin
if [ -n "${PLUGIN_FIELDS_ACTIVE}" ] && [ "${PLUGIN_FIELDS_ACTIVE}" != "0" ]
then
	update_plugin 'fields' "${PLUGIN_FIELDS_VERSION}"
fi

# Manage Entities plugin
if [ -n "${PLUGIN_MANAGEENTITIES_ACTIVE}" ] && [ "${PLUGIN_MANAGEENTITIES_ACTIVE}" != "0" ]
then
	update_plugin 'manageentities' "${PLUGIN_MANAGEENTITIES_VERSION}"
fi

# Manufacturers Imports plugin
if [ -n "${PLUGIN_MANUFACTURESIMPORTS_ACTIVE}" ] && [ "${PLUGIN_MANUFACTURESIMPORTS_ACTIVE}" != "0" ]
then
	update_plugin 'manufacturersimports' "${PLUGIN_MANUFACTURESIMPORTS_VERSION}"
fi

# MReports plugin
if [ -n "${PLUGIN_MREPORTING_ACTIVE}" ] && [ "${PLUGIN_MREPORTING_ACTIVE}" != "0" ]
then
	update_plugin 'mreporting' "${PLUGIN_MREPORTING_VERSION}"
fi

# News plugin
if [ -n "${PLUGIN_NEWS_ACTIVE}" ] && [ "${PLUGIN_NEWS_ACTIVE}" != "0" ]
then
	update_plugin 'news' "${PLUGIN_NEWS_VERSION}"
fi

# Reports plugin
if [ -n "${PLUGIN_REPORTS_ACTIVE}" ] && [ "${PLUGIN_REPORTS_ACTIVE}" != "0" ]
then
	update_plugin 'reports' "${PLUGIN_REPORTS_VERSION}"
fi

# Remove glpi install directory
rm -rf '/var/www/glpi/install'

# Launch Apache2 as Apache user
/usr/sbin/httpd -D FOREGROUND
