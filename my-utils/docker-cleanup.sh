#!/bin/sh

# remove all containers exited 7 days ago
#docker ps -aqf status=exited | xargs -n1 -r docker inspect -f '{{.Id}} {{.Name}} {{.State.FinishedAt}}' | awk '$3 <= "'$(date -d '7 days ago' -Ins --utc | sed 's/+0000/Z/')'" {print $1}' | xargs -r docker rm
docker ps --format "{{.ID}} {{.Names}}" -af status=exited | egrep -v '\-code|rpm\-repo' | awk '{print $1}' | xargs -n1 -r docker inspect -f '{{.Id}} {{.Name}} {{.State.FinishedAt}}' | awk '$3 <= "'$(date -d '7 days ago' -Ins --utc | sed 's/+0000/Z/')'" {print $1}' | xargs -r docker rm

# remove all dangling images
docker images -qf dangling=true | xargs -r docker rmi

# garbage collect in registry_sdn
#docker exec registry_sdn registry garbage-collect /etc/docker/registry/config.yml
