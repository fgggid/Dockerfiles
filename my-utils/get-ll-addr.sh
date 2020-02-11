#!/bin/sh

FILTER_OUT_NH="$(rt --dump 0 | egrep "^169\.254\.0\.0" | awk '{print $5}')"

rt --dump 0 | egrep "^169\.254\." | awk -v NH="$FILTER_OUT_NH" '{ \
    if ($5 != NH) { \
        split($1, f, "/"); \
        HOST=f[1]; IP6=""; \
        "nh --get " $5 " | grep Oif | awk \"{print \\$2}\" | cut -d: -f2" | getline OIF; \
        "vif -g " OIF " | grep IPaddr | awk \"{print \\$3}\" | cut -d: -f2-" | getline IP4; \
        "vif -g " OIF " | grep IP6addr | awk \"{print \\$1}\" | cut -d: -f2-" | getline IP6; \
        "vif -g " OIF " | grep ^vif | awk \"{print \\$3}\"" | getline DEV; \
        if (length(IP6) == 0) { \
            printf "%-15s NIC:%s V4:%s\n", HOST, DEV, IP4; \
        } else { \
            printf "%-15s NIC:%s V6:%s\n", HOST, DEV, IP6; \
        } \
    } \
}'
