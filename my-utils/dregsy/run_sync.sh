#!/bin/sh

# change below as you need
CFG_FILE=$(realpath ./config.yaml)
TAG=queens

if [ ! "x$1" = "x" ]; then
    CFG_FILE=`realpath $1`
# debug
#    echo $CFG_FILE
#    exit
fi

set -e

# make config
grep -L "tags: \['$TAG'\]" $CFG_FILE || sed -i.old "s/tags: \[.*/tags: ['$TAG']/" $CFG_FILE

# sync from hub.docker.com
docker run --privileged --rm -v $CFG_FILE:/config.yaml -v /var/run/docker.sock:/var/run/docker.sock xelalex/dregsy

# clean up
docker images | grep -E ^registry.hub.docker.com/kolla | cut -d' ' -f 1 | xargs -r -I{} docker image rm {}:$TAG
docker images | grep '<none>' | grep 172.18.18.1:6666/kolla | awk '{print $3}' | xargs -r docker image rm
