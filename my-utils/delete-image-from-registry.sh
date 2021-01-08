#!/bin/sh

export Register=https://10.130.176.11:6666
export cLink="/v2/_catalog?n=10"
export cFile=/tmp/.docker.register.catalog
export tFile=/tmp/.docker.register.tags
export wgetC="wget -O- -q -S --no-check-certificate"
tag=$1
# Usage with user/password
# export wgetC="wget -O- -q -S --user=ondra --password=heslo "

if [ "x$tag" = "x" ]; then
  echo Usage:
  echo     $0 [tag]
  exit 0
fi

function listFullCatalog {
  while true; do
# If you need user/password , add --user= and --pasword=  ; Thanks rmetzger
    ${wgetC} "${Register}${cLink}" \
      2>${cFile} \
      | json_pp -t json | grep -F  "      " | cut -d\" -f2 | deleteByTag

      cLink=`grep Link ${cFile} 2>/dev/null | cut -d\< -f2 | cut -d\> -f1`
      if [ ! -n "${cLink}" ] ; then break; fi
  done
}

function deleteByTag {
  cat - | while read image; do
    tLink="/v2/${image}/tags/list?n=10"
    while true; do
      curl -vksSL -X DELETE "${Register}/v2/${image}/manifests/$(
        curl -ksSL -I \
          -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
          "${Register}/v2/${image}/manifests/${tag}" \
        | awk '$1 == "Docker-Content-Digest:" { print $2 }' \
        | tr -d $'\r' \
      )"

      tLink=`grep Link ${tFile} 2>/dev/null | cut -d\< -f2 | cut -d\> -f1`
      if [ ! -n "${tLink}" ] ; then break; fi
    done
  done
}

listFullCatalog
