#!/bin/sh

# Modify schedule of CRON config file
if [ -z "${CRON_SCHEDULE}" ]
then
    CRON_SCHEDULE="*/2 * * * *"
fi
sed -i "s|%%SCHEDULE%%|${CRON_SCHEDULE}|" /etc/crontabs/glpi.cron

# Modify default timezone for PHP
sed -i "s|;date.timezone =|date.timezone=${TZ}|" /etc/php81/php.ini

# Modify default cookie_httponly value for security purpose
sed -i "s|session.cookie_httponly =|session.cookie_httponly = 1|" /etc/php81/php.ini

# Waiting for the installation to be done
echo `date` " - Waiting GLPI to be installed from ppcm/glpi-server"
done_file='/etc/glpi/.installation_done'
while [ ! -f "$done_file" ]
do
    inotifywait -qq -t 30 -e create -e moved_to "$(dirname $done_file)"
done

echo `date` " - Start CRON job"

# Run GLPI cron script
/usr/sbin/crond -f
