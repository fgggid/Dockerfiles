#!/bin/bash

export Register=http://172.18.18.1:6666
export cLink="/v2/_catalog?n=10"
export cFile=/tmp/.docker.register.catalog
export tFile=/tmp/.docker.register.tags
export wgetC="wget -O- -q -S "
# Usage with user/password
# export wgetC="wget -O- -q -S --user=ondra --password=heslo "

function listFullCatalog {

  while true; do
# If you need user/password , add --user= and --pasword=  ; Thanks rmetzger
    ${wgetC} "${Register}${cLink}" \
      2>${cFile} \
      | json_pp -t json | grep -F  "      " | cut -d\" -f2 | listTags

      cLink=`grep Link ${cFile} 2>/dev/null | cut -d\< -f2 | cut -d\> -f1`
      if [ ! -n "${cLink}" ] ; then break; fi
  done
}

function listTags {

  cat - | while read image; do
    tLink="/v2/${image}/tags/list?n=10"
    while true; do
# If you need user/password , add --user= and --pasword=  ; Thanks rmetzger
      ${wgetC} "${Register}${tLink}" \
        2>${tFile} \
        | json_pp -t json | grep -F  "      " | cut -d\" -f2 | sed "s@^@${image}:@"

        tLink=`grep Link ${tFile} 2>/dev/null | cut -d\< -f2 | cut -d\> -f1`
        if [ ! -n "${tLink}" ] ; then break; fi
    done
  done
}

listFullCatalog
