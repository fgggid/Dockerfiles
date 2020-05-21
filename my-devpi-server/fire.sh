#!/bin/sh

#docker run -d --name devpi-server \
#    -e DEVPI_PASSWORD=huayun \
#    -e DEVPI_HOST=178.104.163.176 \
#    -v /root/arsdn_repo/devpi:/data \
#    -p "3141:3141" \
#    --restart always \
#    devpi-server:latest --web --role master

docker-compose up -d
