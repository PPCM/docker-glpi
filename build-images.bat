@echo off

cd glpi-server
docker buildx build --no-cache --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-server:latest .
docker buildx build --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-server:9.5.6-1 .
docker buildx build --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-server:9.5.6 .
docker buildx build --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-server:9.5 .
docker buildx build --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-server:9 .

cd ..\glpi-cron
docker buildx build --no-cache --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-cron:latest .
docker buildx build --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-cron:9.5.6-1 .
docker buildx build --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-cron:9.5.6 .
docker buildx build --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-cron:9.5 .
docker buildx build --push --platform linux/386,linux/amd64,linux/arm/v6,linux/arm64,linux/arm --tag ppcm/glpi-cron:9 .


cd ..
