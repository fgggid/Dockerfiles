#!/bin/sh
set -o pipefail

START=$(date)

if [ "x$1" = "x" ]; then
    echo Usage:
    echo "    $(basename $0) <target> [ options ... ]"
    exit 0
fi

set -x
MY_VER=0000_alfred_dev
TARGET=$1
ERROR_OUTPUT=/tmp/err.log
BUILD_OUTPUT=temp/${TARGET}.log
shift
{
    exec 3>&1    # Save the current stdout (the cat pipe)
    time make -O ${TARGET} $@ SRCVER=${MY_VER} BUILDTAG=${MY_VER} 2>&1 1>&3 | tee ${ERROR_OUTPUT}
} | cat > ${BUILD_OUTPUT}
EXIT_STATUS=$?
set +x

echo "start @ $START"
echo "  now @ $(date)"

if [ $EXIT_STATUS -eq 0 ]; then
    echo ok
else
    echo failure
fi
exit $EXIT_STATUS
