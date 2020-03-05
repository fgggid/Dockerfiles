#!/bin/sh

if [ "x$1" != "x" ]; then
    docker cp `realpath $0` vrouter_vrouter-agent_1:/tmp/get-ll-addr.sh
    echo exec in docker
    docker exec vrouter_vrouter-agent_1 sh -c 'sed -i "s/^    CMD_EXEC=.*$/    CMD_EXEC=/g" /tmp/get-ll-addr.sh; /tmp/get-ll-addr.sh'
    exit 0
else
    CMD_EXEC="docker exec vrouter_vrouter-agent_1"
fi

FILTER_OUT_NH=`$CMD_EXEC rt --dump 0 | egrep "^169\.254\.0\.0" | awk '{print $5}'`

LINES=`$CMD_EXEC rt --dump 0 | egrep "^169\.254\." | awk -v FNH="$FILTER_OUT_NH" '{ if ($5 != FNH) { print } }'`

echo "$LINES" |
while IFS= read -r line
do
    NH=`echo $line | awk '{print $5}'`
    if [ "x$NH" = "x" ]; then
        continue
    fi
    HOST=`echo $line | cut -d/ -f1`
    IP4=""
    IP6=""
    OIF=`$CMD_EXEC nh --get $NH | grep Oif | awk '{print $2}' | cut -d: -f2`
    OIF_INFO=`vif -g $OIF`
    IP4=`echo "$OIF_INFO" | grep IPaddr | awk '{print $3}' | cut -d: -f2-`
    IP6=`echo "$OIF_INFO" | grep IP6addr | awk '{print $1}' | cut -d: -f2-`
    DEV=`echo "$OIF_INFO" | grep ^vif | awk '{print $3}'`
    VIF=`echo "$OIF_INFO" | grep ^vif | awk '{print $1}' | cut -d/ -f2`
    VRF=`echo "$OIF_INFO" | grep Vrf | awk '{print $1}' | cut -d: -f2`
    printf "%-15s NIC:%-16s VRF:%-4s VIF:%-4s V4:%-16s V6:%-39s\n" $HOST $DEV $VRF $VIF $IP4 $IP6
done
