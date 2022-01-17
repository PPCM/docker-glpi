# GLPI Docker Container

## Supported tags

- 9.5.6-1, 9.5.6, 9.5, 9, latest

## Quick reference

- Where to file issues: https://github.com/PPCM/docker-glpi/issues

- Supported architectures: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64)) amd64 arm arm64

## What is GLPI

GLPI is an incredible ITSM software tool that helps you plan and manage IT changes in an easy way, solve problems efficiently when they emerge and allow you to gain legitimate control over your company’s IT budget, and expenses.

[![GLPI Logo](https://github.com/glpi-project/glpi/raw/master/pics/logos/logo-GLPI-100-grey.png)](https://glpi-project.org/fr/)

## About this images

This image contains GLPI with:
- OS: Alpine
- Web Server: Apache2 / PHP
- Following plugins are installed in this package:
    - [Account](https://github.com/InfotelGLPI/accounts)
    - [Addressing](https://github.com/pluginsGLPI/addressing)
    - [Fields](https://github.com/pluginsGLPI/fields)
    - [Fusion Inventory](https://github.com/fusioninventory/fusioninventory-for-glpi)
    - [Manageentities](https://github.com/InfotelGLPI/manageentities)
    - [Manufacturesimports](https://github.com/InfotelGLPI/manufacturersimports)
    - [More reporting GLPI plugin](https://github.com/pluginsGLPI/mreporting)
    - [News GLPI plugin](https://github.com/pluginsGLPI/news)
    - [Additional Reports](https://forge.glpi-project.org/news/415)

Description of each image
- ppcm/glpi-server : This is the web server displaying the UI
- ppcm/glpi-cron : This is the cron jog running every 2 minutes
## How to use this images

### Start `GLPI` with docker
Starting a `GLPI` instance is simple

```console
$ docker network create some-network 
$ docker run -d --name some-mariadb -p 3306:3306 --network some-network -e MARIADB_USER=glpi-user -e MARIADB_PASSWORD=glpi-password -e MARIADB_ROOT_PASSWORD=root-password -e MARIADB_DATABASE=glpi -v mysql-dir:/var/lib/mysql mariadb:latest
$ docker run -d --name some-glpi -p 8089:80 --network some-network -e TZ="Europe/Paris" -v glpi-config:/var/www/glpi/config -v glpi-files:/var/www/glpi/files -v glpi-plugins:/var/www/glpi/plugins -v glpi-marketplace:/var/www/glpi/marketplace ppcm/glpi-server:latest
$ docker run -d --name some-glpi-cron --network some-network -e MYSQL_HOST=some-mariadb -e MYSQL_PORT=3306 -e MYSQL_ROOT_PASSWORD=root-password -e MYSQL_USER=glpi-user -e MYSQL_PASSWORD=glpi-password -e MYSQL_DATABASE=glpi -e LANG=fr_FR -e TZ="Europe/Paris" -v glpi-config:/var/www/glpi/config -v glpi-files:/var/www/glpi/files -v glpi-plugins:/var/www/glpi/plugins -v glpi-marketplace:/var/www/glpi/marketplace ppcm/glpi-cron:latest
```
### Login to GLPI

By default, the following users are created

| function                   | login     | password |
|:---------------------------|:----------|:---------|
| Administrator              | glpi      | glpi     |
| Technician                 | tech      | tech     |
| Standard user              | normal    | normal   |
| Self-service helpdesk user | post-only | postonly |

You are invited to change as soon as possible passwords of this accounts or to remove them.
### Docker informations

#### Exposed ports

| Port      | mariadb | ppcm/glpi-cron | ppcm/glpi-server | Usage                         |
|:---------:|:-------:|:--------------:|:----------------:|:-----------------------------:|
| 80/tcp    |         |                | X                | HTTP web application          |
| 3306/TCP  | X       |                |                  | Mysql/MariaDB port connection |

For SSL, there are many different possibilities to introduce encryption depending on your setup.

As most of available docker image on the internet, it is recommend using a reverse proxy in front of this image. This prevent to introduce all ssl configurations parameters and also to prevent a limitation of the available parameters.

For example, you can use the popular nginx-proxy and docker-letsencrypt-nginx-proxy-companion containers or Traefik to handle this.

#### Environments variables

| Environment         | mariadb | ppcm/glpi-cron | ppcm/glpi-server | Default       | Usage                                     |
|:--------------------|:-------:|:--------------:|:----------------:|:-------------:|:------------------------------------------|
| MYSQL_HOST          |         | X              |                  |               | MANDATORY - MySQL or MariaDB host name    |
| MYSQL_PORT          |         | X              |                  | 3306          | MySQL or MariaDB host port                |
| MYSQL_ROOT_PASSWORD | X       | X              |                  |               | MySQL or MariaDB root password, it is needed to create database and user. It is also needed to configure properly the user. It can be set only on first start of the applkcation. |
| MYSQL_USER          | X       | X              |                  | glpi-user     | MySQL or MariaDB GLPI username            |
| MYSQL_PASSWORD      | X       | X              |                  | glpi-password | MySQL or MariaDB password for GLPI user   |
| MYSQL_DATABASE      | X       | X              |                  | glpi          | MySQL or MariaDB database name for GLPI   |
| LANG                |         | X              |                  | fr_FR         | Default language of GLPI                  |
| TZ                  |         | X              | X                | Europe/Paris  | Timezone of the web server                |

#### Exposed volumes
Volumes must be exposed both for `ppcm/glpi-server` and `ppcm/glpi-cron`

| Volume                    | Usage                                                     |
|:--------------------------|:----------------------------------------------------------|
| /var/www/glpi/config      | The configuration path of GLPI                            |
| /var/www/glpi/files       | The path for stored files in GLPI                         |
| /var/www/glpi/plugins     | The path for plugins in GLPI                              |
| /var/www/glpi/marketplace | The path for plugins downloaded from the GLPI marketplace |

#### GLPI Cronjob

GLPI require a job to be run periodically.
To respect docker convention and to prevent a clustered deploiement to run the cron on all cluster instances, the cron task was removed from GLPI main image.

As compensation a dedicated image was made for the cron task. Only one instance of this image has to run on your cluster.
