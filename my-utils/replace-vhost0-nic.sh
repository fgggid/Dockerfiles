#!/bin/sh
set -e
DEBUG=1
if [ ${DEBUG} -ne 0 ]; then
    DBG_OUT=echo
else
    DBG_OUT=
fi

CONTRAIL_DIR=/etc/contrail

### input check
NEW_NIC=$1
NEW_NIC_CFG=/etc/sysconfig/network-scripts/ifcfg-${NEW_NIC}
OLD_VHOST0_CFG=/etc/sysconfig/network-scripts/ifcfg-vhost0
if [ ! -f ${NEW_NIC_CFG} ] || [ "${NEW_NIC}" = "vhost0" ]; then
    echo No config file found, please input a proper NIC name!!!
    exit 1
fi
NEW_VTEP_IP=$(grep IPADDR ${NEW_NIC_CFG} | awk -F '=' '{print $2}')
NEW_PATTERN=$(echo ${NEW_VTEP_IP} | awk -F '.' '{print $1 "." $2 "." $3 "."}')

### sanity check
## 1. get old VTEP_IP
OLD_VTEP_IP=$(grep VROUTER_GATEWAY /etc/contrail/common_vrouter.env | awk -F '=' '{print $2}')
OLD_PATTERN=$(echo ${OLD_VTEP_IP} | awk -F '.' '{print $1 "." $2 "." $3 "."}')

## 2. get old VTEP prefix/netmask, make sure it is /24
if [ ! -f ${OLD_VHOST0_CFG} ]; then
    echo You don\'t have old vhost0 config
    exit 1
fi

# prefix
OLD_PREFIX=$(grep PREFIX ${OLD_VHOST0_CFG} | awk -F '=' '{print $2}')
OLD_PREFIX=${OLD_PREFIX:-24}
# netmask
OLD_NETMASK=$(grep NETMASK ${OLD_VHOST0_CFG} | awk -F '=' '{print $2}')
OLD_NETMASK=${OLD_NETMASK:-255.255.255.0}
echo OLD_PREFIX=${OLD_PREFIX}
echo OLD_NETMASK=${OLD_NETMASK}
if [ "$OLD_PREFIX" != "24" ] || [ "${OLD_NETMASK}" != "255.255.255.0" ]; then
    echo vhost0 prefix is NOT 24, it is not supported, please revise script.
    exit 1
fi

## x. display all info
echo NEW_NIC=${NEW_NIC}
echo OLD_VTEP_IP=${OLD_VTEP_IP}
echo NEW_VTEP_IP=${NEW_VTEP_IP}
echo OLD_PATTERN=${OLD_PATTERN}
echo NEW_PATTERN=${NEW_PATTERN}

if [ ${DEBUG} -ne 0 ]; then
    echo -e "\nIn DEBUG mode!!! Will not do anything, just print what commands will do."
fi

while true; do
    read -p "Please check above parameters, are you sure to change NIC of vhost0? " yn
    case $yn in
        [Yy]* ) echo -e "\n"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

### start replace
${DBG_OUT} docker stop vrouter_vrouter-agent_1 && \
${DBG_OUT} ifdown vhost0 && \
${DBG_OUT} rm -f ${OLD_VHOST0_CFG}

if [ "${OLD_PATTERN}" != "${NEW_PATTERN}" ]; then
    if [ ${DEBUG} -ne 0 ]; then
        ## debug output
        grep -r "VROUTER_GATEWAY=${OLD_PATTERN}" $CONTRAIL_DIR | awk -F ':' '{print $1}' | xargs -r -n1 sed "s@VROUTER_GATEWAY=${OLD_PATTERN}@VROUTER_GATEWAY=${NEW_PATTERN}@g" | grep VROUTER_GATEWAY=
    else
        ## real replace
        grep -r "VROUTER_GATEWAY=${OLD_PATTERN}" $CONTRAIL_DIR | awk -F ':' '{print $1}' | xargs -r -n1 sed -i "s@VROUTER_GATEWAY=${OLD_PATTERN}@VROUTER_GATEWAY=${NEW_PATTERN}@g"
    fi
fi

${DBG_OUT} pushd /etc/contrail/vrouter && \
${DBG_OUT} docker-compose up -d && \
${DBG_OUT} popd
