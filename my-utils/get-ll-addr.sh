#!/bin/sh

FILTER_OUT_NH="$(rt --dump 0 | egrep "^169\.254\.0\.0" | awk '{print $5}')"

LINES=`rt --dump 0 | egrep "^169\.254\." | awk -v FNH="$FILTER_OUT_NH" '{ if ($5 != FNH) { print } }'`

echo "$LINES" |
while IFS= read -r line
do
    NH=`echo $line | awk '{print $5}'`
    if [ "x$NH" = "x" ]; then
        continue
    fi
    HOST=`echo $line | cut -d/ -f1`
    IP6=""
    OIF=`nh --get $NH | grep Oif | awk '{print $2}' | cut -d: -f2`
    OIF_INFO=`vif -g $OIF`
    IP4=`echo "$OIF_INFO" | grep IPaddr | awk '{print $3}' | cut -d: -f2-`
    IP6=`echo "$OIF_INFO" | grep IP6addr | awk '{print $1}' | cut -d: -f2-`
    DEV=`echo "$OIF_INFO" | grep ^vif | awk '{print $3}'`
    VIF=`echo "$OIF_INFO" | grep ^vif | awk '{print $1}' | cut -d/ -f2`
    VRF=`echo "$OIF_INFO" | grep Vrf | awk '{print $1}' | cut -d: -f2`
    if [ "x$IP6" = "x" ]; then
        printf "%-15s NIC:%s V4:%-39s\tVRF:%s VIF:%s\n" $HOST $DEV $IP4 $VRF $VIF
    else
        printf "%-15s NIC:%s V6:%-39s\tVRF:%s VIF:%s\n" $HOST $DEV $IP6 $VRF $VIF
    fi
done
