#!/bin/sh
#set -x

OLD_TAG=$1
NEW_TAG=$2
OUTPUT_FILE=/tmp/.${USER}.manifest-push.sh

usage () {
    echo Usage:
    echo "    $0 <old tag> <new tag>"
}

if [ "x$OLD_TAG" == "x" -o "x$NEW_TAG" == "x" ]; then
    usage
    exit 0
fi

IMAGE_LIST=$(docker images | grep " ${OLD_TAG} " | awk '{print $1}')

echo "set -e" > ${OUTPUT_FILE}
echo "set -x" >> ${OUTPUT_FILE}

echo "${IMAGE_LIST}" | awk -v _new_tag="${NEW_TAG}" '{print "docker manifest create "$1":"_new_tag" "$1":"_new_tag"-x86_64 "$1":"_new_tag"-aarch64 --insecure"}' | xargs -rn7 >> ${OUTPUT_FILE}
echo "${IMAGE_LIST}" | awk -v _new_tag="${NEW_TAG}" '{print "docker manifest annotate "$1":"_new_tag" "$1":"_new_tag"-x86_64 --os linux --arch amd64"}' | xargs -rn9 >> ${OUTPUT_FILE}
echo "${IMAGE_LIST}" | awk -v _new_tag="${NEW_TAG}" '{print "docker manifest annotate "$1":"_new_tag" "$1":"_new_tag"-aarch64 --os linux --arch arm64 --variant v8"}' | xargs -rn11 >> ${OUTPUT_FILE}
echo "${IMAGE_LIST}" | awk -v _new_tag="${NEW_TAG}" '{print "docker manifest push "$1":"_new_tag" --insecure -p"}' | xargs -rn6 >> ${OUTPUT_FILE}

echo script is ${OUTPUT_FILE}, please check before run it
