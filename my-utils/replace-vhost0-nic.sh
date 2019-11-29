#!/bin/sh
set -e
CONTRAIL_DIR=/etc/contrail

### input check
NEW_NIC=$1
NEW_NIC_CFG=/etc/sysconfig/network-scripts/ifcfg-${NEW_NIC}
OLD_VHOST0_CFG=/etc/sysconfig/network-scripts/ifcfg-vhost0
if [ ! -f ${NEW_NIC_CFG} ]; then
    echo Please input NIC name!!!
    exit 1
fi
NEW_VTEP_IP=$(grep IPADDR ${NEW_NIC_CFG} | awk -F '=' '{print $2}')
NEW_PATTERN=$(echo ${NEW_VTEP_IP} | awk -F '.' '{print $1 "." $2 "." $3 "."}')

### sanity check
## 1. get old VTEP_IP
OLD_VTEP_IP=$(grep VROUTER_GATEWAY /etc/contrail/common_vrouter.env | awk -F '=' '{print $2}')
OLD_PATTERN=$(echo ${OLD_VTEP_IP} | awk -F '.' '{print $1 "." $2 "." $3 "."}')

## 2. get old VTEP netmask, make sure it is /24
if [ ! -f ${OLD_VHOST0_CFG} ]; then
    echo You don\'t have old vhost0 config
    exit 1
fi
OLD_PREFIX=$(grep PREFIX ${OLD_VHOST0_CFG} | awk -F '=' '{print $2}')
echo OLD_PREFIX=${OLD_PREFIX}
if [ "$OLD_PREFIX" != "24" ]; then
    echo vhost prefix is NOT 24, are you sure, please revise script.
    exit 1
fi

## x. display all info
echo NEW_NIC=${NEW_NIC}
echo OLD_VTEP_IP=${OLD_VTEP_IP}
echo NEW_VTEP_IP=${NEW_VTEP_IP}
echo OLD_PATTERN=${OLD_PATTERN}
echo NEW_PATTERN=${NEW_PATTERN}

### start replace
docker stop vrouter_vrouter-agent_1 && \
ifdown vhost0 && \
rm ${OLD_VHOST0_CFG}

## debug display
#grep -r "VROUTER_GATEWAY=${OLD_PATTERN}" $CONTRAIL_DIR | awk -F ':' '{print $1}' | xargs -r -n1 sed "s@VROUTER_GATEWAY=${OLD_PATTERN}@VROUTER_GATEWAY=${NEW_PATTERN}@g" | grep VROUTER_GATEWAY=
## real replace
grep -r "VROUTER_GATEWAY=${OLD_PATTERN}" $CONTRAIL_DIR | awk -F ':' '{print $1}' | xargs -r -n1 sed -i "s@VROUTER_GATEWAY=${OLD_PATTERN}@VROUTER_GATEWAY=${NEW_PATTERN}@g"

pushd /etc/contrail/vrouter
docker-compose up -d
popd
