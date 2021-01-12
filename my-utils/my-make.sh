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
shift
{
    exec 3>&1    # Save the current stdout (the cat pipe)
    make -O ${TARGET} $@ SRCVER=${MY_VER} BUILDTAG=${MY_VER} 2>&1 1>&3 | tee /tmp/err.log
} | cat > temp/${TARGET}.log
set +x

echo "start @ $START"
echo "  now @ $(date)"
