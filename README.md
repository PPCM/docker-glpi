# GLPI Docker Container

## Supported tags

- 10, 10.0, 10.0.16, 10.0.16-3, latest
- 10.0.15, 10.0.15-2
- 10.0.14, 10.0.14-1
- 10.0.12, 10.0.12-3
- 10.0.11, 10.0.11-4
- 10.0.10, 10.0.10-4
- 10.0.9, 10.0.9-2
- 10.0.7, 10.0.7-5
- 10.0.6, 10.0.6-1

## Quick reference

- Where to file issues: https://github.com/PPCM/docker-glpi/issues

- Supported architectures: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64)) amd64 386 arm/v6 arm/v7 arm64

## What is GLPI

GLPI is an incredible ITSM software tool that helps you plan and manage IT changes in an easy way, solve problems efficiently when they emerge and allow you to gain legitimate control over your company’s IT budget, and expenses.

[![GLPI Logo](https://glpi-project.org/wp-content/uploads/2021/06/GLPI_by_Teclib.png)](https://glpi-project.org/fr/)

## About Docker GLPI

This package contains with:
- OS: Alpine
- Web Server: Apache2 / PHP
- GLPI application
- Following plugins are installed in this package:
    - [Accounts](https://github.com/InfotelGLPI/accounts)
    - [Fields](https://github.com/pluginsGLPI/fields)
    - [Manageentities](https://github.com/InfotelGLPI/manageentities)
    - [Manufacturesimports](https://github.com/InfotelGLPI/manufacturersimports)
    - [More reporting](https://github.com/pluginsGLPI/mreporting)
    - [News](https://github.com/pluginsGLPI/news)
    - [Additional Reports](https://github.com/yllen/reports)
    - [GLPI Inventory](https://github.com/glpi-project/glpi-inventory-plugin)

Description of each image
- ppcm/glpi-server : GLPI web server with the UI
- ppcm/glpi-cron : GLPI cron job, you are in charge for the scheduling (start the job as you want)
- ppcm/glpi-cron-daemon : GLPI cron job daemon is running with scheduling managed
## How to use this images

### Start `GLPI` with docker
Starting a `GLPI` instance is simple

```console
$ docker network create some-network 
$ docker run -d --name some-mariadb -p 3306:3306 --network some-network -e MARIADB_USER=glpi-user -e MARIADB_PASSWORD=glpi-password -e MARIADB_ROOT_PASSWORD=root-password -e MARIADB_DATABASE=glpi -v mysql-dir:/var/lib/mysql mariadb:latest
$ docker run -d --name some-glpi -p 8089:80 --network some-network -e MYSQL_HOST=some-mariadb -e MYSQL_PORT=3306 -e MYSQL_ROOT_PASSWORD=root-password -e MYSQL_USER=glpi-user -e MYSQL_PASSWORD=glpi-password -e MYSQL_DATABASE=glpi -e LANG=fr_FR -e TZ="Europe/Paris" -v glpi-config:/etc/glpi -v glpi-files:/var/glpi/files -v glpi-plugins:/var/www/glpi/plugins -v glpi-marketplace:/var/www/glpi/marketplace ppcm/glpi-server:latest
````
Now you have the choice
- Manage the scheduling by yourself and free ressources between each launch - You have to start the pod each time you want to execute to cron job
```console
$ docker run -d --name some-glpi-cron --network some-network -e TZ="Europe/Paris" -v glpi-config:/var/glpi/config -v glpi-files:/etc/glpi -v glpi-plugins:/var/www/glpi/plugins -v glpi-marketplace:/var/www/glpi/marketplace ppcm/glpi-cron:latest
```
- Launch a deamon which schedules by itself
```console
$ docker run -d --name some-glpi-cron-daemon --network some-network -e CRON_SCHEDULE="*/2 * * * *" -e TZ="Europe/Paris" -v glpi-config:/etc/glpi -v glpi-files:/var/glpi/files -v glpi-plugins:/var/www/glpi/plugins -v glpi-marketplace:/var/www/glpi/marketplace ppcm/glpi-cron-daemon:latest
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

| Port      | mariadb | ppcm/glpi-server | Usage                         |
|:---------:|:-------:|:----------------:|:-----------------------------:|
| 80/tcp    |         | X                | HTTP web application          |
| 3306/TCP  | X       |                  | Mysql/MariaDB port connection |

For SSL, there are many different possibilities to introduce encryption depending on your setup.

As most of available docker image on the internet, it is recommend using a reverse proxy in front of this image. This prevent to introduce all ssl configurations parameters and also to prevent a limitation of the available parameters.

For example, you can use the popular nginx-proxy and docker-letsencrypt-nginx-proxy-companion containers or Traefik to handle this.

#### Environments variables
For plugins variables, any content, except 0, will install, update and activate the plugin.

| Environment                       | mariadb | ppcm/glpi-cron-deamon | ppcm/glpi-cron | ppcm/glpi-server | Default       | Usage                                                |
|:----------------------------------|:-------:|:---------------------:|:--------------:|:----------------:|:-------------:|:-----------------------------------------------------|
| MYSQL_HOST                        |         |                       |                | X                |               | MANDATORY - MySQL or MariaDB host name               |
| MYSQL_PORT                        |         |                       |                | X                | 3306          | MySQL or MariaDB host port                           |
| MYSQL_ROOT_PASSWORD               | X       |                       |                | X                |               | MySQL or MariaDB root password, it is needed to create database and user. If you already configured the user and the database, it is not mandatory |
| MYSQL_USER                        | X       |                       |                | X                | glpi-user     | MySQL or MariaDB GLPI username                       |
| MYSQL_PASSWORD                    | X       |                       |                | X                | glpi-password | MySQL or MariaDB password for GLPI user              |
| MYSQL_DATABASE                    | X       |                       |                | X                | glpi          | MySQL or MariaDB database name for GLPI              |
| LANG                              |         |                       |                | X                | fr_FR         | Default language of GLPI                             |
| TZ                                |         | X                     | X              | X                | Europe/Paris  | Timezone of the web server                           |
| CRON_SCHEDULE                     |         | X                     |                |                  | */2 * * * *   | Schedule in CRON format - [cron.guru](https://crontab.guru/) can help you to define it |
| PLUGIN_ACCOUNT_ACTIVE             |         |                       |                | X                | 1             | Install / Update / Active Plugin Accounts            |
| PLUGIN_FIELDS_ACTIVE              |         |                       |                | X                | 1             | Install / Update / Active Plugin Fields              |
| PLUGIN_MANAGEENTITIES_ACTIVE      |         |                       |                | X                | 1             | Install / Update / Active Plugin Manageentities      |
| PLUGIN_MANUFACTURESIMPORTS_ACTIVE |         |                       |                | X                | 1             | Install / Update / Active Plugin Manufacturesimports |
| PLUGIN_MREPORTING_ACTIVE          |         |                       |                | X                | 1             | Install / Update / Active Plugin More reporting      |
| PLUGIN_NEWS_ACTIVE                |         |                       |                | X                | 1             | Install / Update / Active Plugin News                |
| PLUGIN_REPORTS_ACTIVE             |         |                       |                | X                | 1             | Install / Update / Active Plugin Additional Reports  |
| PLUGIN_GLPIINVENTORY_ACTIVE       |         |                       |                | X                | 1             | Install / Update / Active Plugin GLPI Inventory      |

#### Exposed volumes
Volumes must be exposed for `ppcm/glpi-server`, `ppcm/glpi-cron` and  `ppcm/glpi-cron-daemon`

| Volume                    | Usage                                                     |
|:--------------------------|:----------------------------------------------------------|
| /etc/glpi                 | The configuration path of GLPI                            |
| /var/glpi/files           | The path for stored files in GLPI                         |
| /var/www/glpi/plugins     | The path for plugins in GLPI                              |
| /var/www/glpi/marketplace | The path for plugins downloaded from the GLPI marketplace |

#### GLPI Cronjob

GLPI require a job to be run periodically.
To respect docker convention and to prevent a clustered deploiement to run the cron on all cluster instances, the cron task was removed from GLPI main image.

As compensation 2 dedicated images were made for the cron task. Only one instance of this images has to run on your cluster.

2 ways to run the cron job (only one solution should be used):

- ppcm/glpi-cron : GLPI cron job, you are in charge for the scheduling - You have to start the pod each time you want to execute to cron job - The advantage of this solution is that ressources are released when it is not needed
- ppcm/glpi-cron-daemon : GLPI cron job daemon is running with scheduling managed by an environment variable - The advantage of this solution is that you don't have to care about an external solution for the cron
