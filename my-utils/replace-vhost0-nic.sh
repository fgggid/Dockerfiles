#!/usr/bin/env bash
set -e
DEBUG=1
if [ ${DEBUG} -ne 0 ]; then
    DBG_OUT=echo
else
    DBG_OUT=
fi

BACKUP_DIR=/etc/sysconfig/network-scripts/bak
CONTRAIL_DIR=/etc/contrail

### input check
NEW_NIC=$1
NEW_NIC_CFG=/etc/sysconfig/network-scripts/ifcfg-${NEW_NIC}
OLD_VHOST0_CFG=/etc/sysconfig/network-scripts/ifcfg-vhost0
if [ ! -f ${NEW_NIC_CFG} ] || [ "${NEW_NIC}" = "vhost0" ]; then
    echo No config file found, please input a proper NIC name!!!
    exit 1
fi
NEW_VTEP_IP=$(grep IPADDR ${NEW_NIC_CFG} | awk -F '=' '{print $2}' | xargs)
NEW_PATTERN=$(echo ${NEW_VTEP_IP} | awk -F '.' '{print $1 "." $2 "." $3 "."}')

### sanity check
## 1. new VTEP IP check
IP_RE='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
 IP_RE+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
if [[ ! ${NEW_VTEP_IP} =~ $IP_RE ]]; then
    echo New VTEP IP: ${NEW_VTEP_IP} is not valid!
    exit 1
fi

## 2. get old BIND_INT
OLD_NIC=$(grep BIND_INT ${OLD_VHOST0_CFG} | awk -F '=' '{print $2}' | xargs)
OLD_NIC_CFG=/etc/sysconfig/network-scripts/ifcfg-${OLD_NIC}

if [ ! -f ${OLD_NIC_CFG} ]; then
    echo You don\'t have old nic config: ${OLD_NIC_CFG}, please keep it until you\'ve finished this replacement.
    exit 1
fi

if [ "${OLD_NIC}" = "${NEW_NIC}" ]; then
    echo You don\'t change NIC, exit!!!
    exit 1
fi

## 3. get old VTEP_IP
OLD_VTEP_IP=$(grep IPADDR ${OLD_NIC_CFG} | awk -F '=' '{print $2}' | xargs)
OLD_PATTERN=$(echo ${OLD_VTEP_IP} | awk -F '.' '{print $1 "." $2 "." $3 "."}')

## 4. get old VTEP prefix/netmask, make sure it is /24
if [ ! -f ${OLD_VHOST0_CFG} ]; then
    echo You don\'t have old vhost0 config
    exit 1
fi

# prefix
OLD_PREFIX=$(grep PREFIX ${OLD_VHOST0_CFG} | awk -F '=' '{print $2}' | xargs)
OLD_PREFIX=${OLD_PREFIX:-24}
# netmask
OLD_NETMASK=$(grep NETMASK ${OLD_VHOST0_CFG} | awk -F '=' '{print $2}' | xargs)
OLD_NETMASK=${OLD_NETMASK:-255.255.255.0}
#echo OLD_PREFIX=${OLD_PREFIX}
#echo OLD_NETMASK=${OLD_NETMASK}
if [ "${OLD_PREFIX}" != "24" ] || [ "${OLD_NETMASK}" != "255.255.255.0" ]; then
    echo vhost0 prefix is NOT 24, it is not supported, please revise script.
    exit 1
fi

### display all info
echo OLD_NIC=${OLD_NIC}
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
else
    ## IP is same, we need to down old nic, and bring up new nic
    ${DBG_OUT} ifdown ${OLD_NIC}
    ${DBG_OUT} ifup ${NEW_NIC}
fi

if [ ${DEBUG} -ne 0 ]; then
    ## debug output
    grep -r "PHYSICAL_INTERFACE=${OLD_NIC}" $CONTRAIL_DIR | awk -F ':' '{print $1}' | xargs -r -n1 sed "s@PHYSICAL_INTERFACE=${OLD_NIC}@PHYSICAL_INTERFACE=${NEW_NIC}@g" | grep PHYSICAL_INTERFACE=
else
    ## real replace
    grep -r "PHYSICAL_INTERFACE=${OLD_NIC}" $CONTRAIL_DIR | awk -F ':' '{print $1}' | xargs -r -n1 sed -i "s@PHYSICAL_INTERFACE=${OLD_NIC}@PHYSICAL_INTERFACE=${NEW_NIC}@g"
fi

### backup old nic cfg
if [ ! -d ${BACKUP_DIR} ]; then
    ${DBG_OUT} mkdir -p ${BACKUP_DIR}
fi
${DBG_OUT} mv -f ${OLD_NIC_CFG} ${BACKUP_DIR}
echo ${OLD_NIC_CFG} is moved to ${BACKUP_DIR} .

${DBG_OUT} pushd /etc/contrail/vrouter && \
${DBG_OUT} docker-compose up -d && \
${DBG_OUT} popd
