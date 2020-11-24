#!/bin/sh

OLD_TAG=$1
NEW_TAG=$2
OUTPUT_FILE=/tmp/.${USER}.rename_tag.sh

usage () {
    echo Usage:
    echo "    $0 <old tag> <new tag>"
}

if [ "x$OLD_TAG" == "x" -o "x$NEW_TAG" == "x" ]; then
    usage
    exit 0
fi

IMAGE_LIST=$(docker images | grep ${OLD_TAG})

echo "${IMAGE_LIST}" | awk -v _new_tag="${NEW_TAG}" '{print "docker tag "$3" "$1":"_new_tag}' | xargs -rn 4 > ${OUTPUT_FILE}
echo "${IMAGE_LIST}" | awk -v _new_tag="${NEW_TAG}" '{print "docker push "$1":"_new_tag}' | xargs -rn 3 >> ${OUTPUT_FILE}
echo "${IMAGE_LIST}" | awk -v _new_tag="${NEW_TAG}" '{print "docker rmi "$1":"_new_tag}' | xargs -rn 3 >> ${OUTPUT_FILE}

echo script is ${OUTPUT_FILE}, please check before run it
