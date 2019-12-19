#!/bin/sh

FILTER_OUT_NH="$(rt --dump 0 | egrep "^169\.254\.0\.0" | awk '{print $5}')"

rt --dump 0 | egrep "^169\.254\." | awk -v NH="$FILTER_OUT_NH" '{ \
    if ($5 != NH) { \
        split($1, f, "/"); \
        HOST=f[1]; \
        "nh --get " $5 " | grep Oif | awk \"{print \\$2}\" | cut -d: -f2" | getline OIF; \
        "vif -g " OIF " | grep IPaddr | awk \"{print \\$3}\" | cut -d: -f2-" | getline IP4; \
        "vif -g " OIF " | grep IP6addr | awk \"{print \\$1}\" | cut -d: -f2-" | getline IP6; \
        if (length(IP6) == 0) { \
            print HOST " V4:" IP4; \
        } else { \
            print HOST " V6:" IP6; \
        } \
    } \
}'
