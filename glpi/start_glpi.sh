#!/bin/sh

# Remove glpi install directory
rm -rf /var/www/glpi/install

# Modify default timezone for PHP
sed -i "s|;date.timezone =|date.timezone=${TZ}|" /etc/php7/php.ini

# Waiting for the installation to be done
echo "Waiting GLPI to be installed from ppcm/glpi-cron"
done_file='/var/www/glpi/config/.installation_done'
while [ ! -f "$done_file" ]
do
    inotifywait -qq -t 30 -e create -e moved_to "$(dirname $done_file)"
done
echo "GLPI installation done"

# Launch Apache2
/usr/sbin/httpd -D FOREGROUND
