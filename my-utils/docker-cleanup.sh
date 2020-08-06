#!/bin/sh

PREV=$(df -h /)
# remove all containers exited 1 days ago
#docker ps -aqf status=exited | xargs -n1 -r docker inspect -f '{{.Id}} {{.Name}} {{.State.FinishedAt}}' | awk '$3 <= "'$(date -d '7 days ago' -Ins --utc | sed 's/+0000/Z/')'" {print $1}' | xargs -r docker rm
docker ps --format "{{.ID}} {{.Names}}" -af status=exited | egrep -v '\-code|rpm\-repo' | awk '{print $1}' | xargs -n1 -r docker inspect -f '{{.Id}} {{.Name}} {{.State.FinishedAt}}' | awk '$3 <= "'$(date -d '1 day ago' -Ins --utc | sed 's/+0000/Z/')'" {print $1}' | xargs -r docker rm > /dev/null 2>&1

# prune
counter=0
while [ $counter -lt 10 ]; do
  docker image prune -f | grep "Total reclaimed space: 0B" > /dev/null 2>&1 && break
  counter=`expr $counter + 1`
done

# remove all dangling images
#docker images -qf dangling=true | xargs -r docker rmi > /dev/null 2>&1

# garbage collect in registry_sdn
docker exec registry_sdn registry garbage-collect /etc/docker/registry/config.yml --delete-untagged=true > /dev/null 2>&1

POST=$(df -h /)

echo -e "Before clean up: \n$PREV"
echo -e "\nAfter clean up: \n$POST"
