#!/bin/sh

docker run -d --name devpi-server \
    -e DEVPI_PASSWORD=huayun \
    -e DEVPI_HOST=10.130.176.10 \
    -v "${PWD}/data":/data \
    -p "3141:3141" \
    --restart always \
    devpi-server:latest --web --role replica --master-url http://178.104.163.176:3141
