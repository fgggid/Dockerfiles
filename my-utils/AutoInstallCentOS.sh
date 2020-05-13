#!/bin/bash
# for debug
#set -x

# 拷贝当前文件到需要重装的系统内，修改与Mirror相通信的网卡名、地址、网关等信息,不填写则默认抓取系统的值
# 修改完成后执行此脚本，等待重启完成系统安装
# 如果需要安装其他的centos系统则需要修改Install_Mirror路径，指向ISO挂载的http网站url


#NETDEV=ens192
#IPADDR=172.118.45.250
#GATEWAY=172.118.45.1
#NETMASK=255.255.255.0
#DNS=114.114.114.114


Install_OS="centos"
#OS_Type='7.2.1511'
#OS_Type='7.5.1804'
OS_Type='7.6.1810'
OS_Arch="x86_64"

Install_Mirror="http://172.16.41.30:8081/install/$OS_Type/os/$OS_Arch"
# wuxi

#Install_Mirror="http://10.130.180.201/ISO/1810/"
# shenzheng

PASSWORD='Huayun@123'


##-------------------------- disk config ----------------------------------------------------------
PartType=`lsblk -l|grep -w '/'|awk '{print $6}'`
if [ "$PartType" = "lvm" ]; then
    RootLV=`lsblk -l|grep -w '/'|awk '{print $1}'`
    VgName=`dmsetup splitname $RootLV | tail -1 | awk '{print $1}'`
    BasePart=`pvs | grep $VgName | awk '{print $1}' | tr -d 0-9`
else
    BasePart=`lsblk -l|grep -w '/'|awk '{print $1}'|tr -d 0-9`
fi
PartType=`lsblk -l|grep -w '\[SWAP\]'|awk '{print $6}'`
if [ "$PartType" = "lvm" ]; then
    SwapLV=`lsblk -l|grep -w '\[SWAP\]'|awk '{print $1}'`
    VgName=`dmsetup splitname $SwapLV | tail -1 | awk '{print $1}'`
    SwapPart=`pvs | grep $VgName | awk '{print $1}' | tr -d 0-9`
else
    SwapPart=`lsblk -l|grep -w '\[SWAP\]'|awk '{print $1}'|tr -d 0-9`
fi
SwapSize=$(expr `free -h |grep "Swap" |awk '{print $2}'|awk -F. '{print $1}'|sed 's/G//g'` \* 1024)
BootPart=`lsblk -l|grep -w '/boot'|awk '{print $1}'|tr -d 0-9`
BootSize=$(expr `lsblk -b --output SIZE,FSTYPE |grep -w swap |awk '{print $1}'` / 1024 / 1024)

DEVPATH=`lsblk -l |grep  '/boot' |awk '{print $1}'`

#if [[ `dmidecode | grep "HUAYUN" | wc -l` > 0 ]]; then
#  DEVPATH=$(echo $DEVPATH | sed "s/$BootPart/sda/g")
#  BasePart=sda
#  SwapPart=sda
#  BootPart=sda
#fi

## net config by default route ##
NETDEV=$(ip r | grep default | awk '{print $5}')
IPADDR=$(ip -4 -o a show $NETDEV | head -1 | awk '{print $4}' | cut -d/ -f 1)
PREFIX=$(ip -4 -o a show $NETDEV | head -1 | awk '{print $4}' | cut -d/ -f 2)
NETMASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/'${PREFIX}'' |cut -d'/' -f1)";
GATEWAY=$(ip r | grep default | awk '{print $3}')
DNS=$(egrep "^nameserver" /etc/resolv.conf | head -1 | awk '{print $2}')
if [ "x$DNS" = "x" ]; then
    DNS=114.114.114.114
fi

# get real dev
NETDEV=$(ip -o l show $NETDEV | awk '{print $2}' | cut -d: -f 1 | cut -d@ -f 2)


#### DEBUG ####
echo BasePart: $BasePart
echo SwapPart: $SwapPart
echo SwapSize: $SwapSize
echo BootPart: $BootPart
echo BootSize: $BootSize
echo DEVPATH : $DEVPATH

echo NETDEV : $NETDEV
echo IPADDR : $IPADDR
echo NETMASK: $NETMASK
echo GATEWAY: $GATEWAY
echo DNS    : $DNS

# debug exit, we just want to see output
#exit 0

### confirm to continue
echo -e \\nThere is no way back if you choose yes.\\nPlease DO check above parameters.
read -p "Are you sure? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo You want to check more, take your time.
    exit 0
fi

read -p "Are you REALLY sure? (yes/not) " -n 3 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo You want to check more, take your time.
    exit 0
fi

### mirror check
#--------------------------------------------------------------------------------------------------
httpResponse=$(curl -o /dev/null -s -w %{http_code} $Install_Mirror/isolinux/initrd.img)
if [[ $httpResponse == '404' ]];then
  echo -ne "\033[31mMirror failed, url does not exist\033[0m\n"
  exit 1
fi

##--------------------------- install --------------------------------------------------------------

if [[ -z $BasePart ]];then
  BasePart=sda
fi

if [[ -z $SwapPart ]];then
  SwapPart=sda
fi

if [[ -z $SwapSize ]];then
  SwapSize=8192
fi

if [[ -z $BootPart ]];then
  BootPart=sda
fi

if [[ -z $BootSize ]];then
  BootSize=500
fi

ClearDisk=
for disk in `echo $SwapPart $BootPart $BasePart |sed "s/\ /\\n/g"  |sort -u`;do if [[ $ClearDisk ]];then ClearDisk=$ClearDisk,$disk;else ClearDisk=$disk ;fi;done

IgnoreDisk=
for disk in `lsblk|sed -e '/NAME/d' -e "/$BootPart/d" -e "/$SwapPart/d" -e "/$BasePart/d" -e '/loop/d' |awk '{print $1}'`; do if [[ $IgnoreDisk ]];then IgnoreDisk=$IgnoreDisk,$disk;else IgnoreDisk=$disk ;fi ;done

if [[ -z $NETDEV ]];then
  NETDEV=$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}');
fi

IPSUB="$(ip addr |grep ''${NETDEV}'' |grep 'global' |grep 'brd' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')";
NETSUB="$(echo -n "$IPSUB" |grep -o '/[0-9]\{1,2\}')";

if [[ -z $IPADDR ]];then
  IPADDR=$(echo -n "$IPSUB" |cut -d'/' -f1);
fi

if [[ -z $GATEWAY ]];then
  GATEWAY=$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}');
fi

MASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/'${NETSUB}'' |cut -d'/' -f1)";
# -----------------------------------------------------------------------------

clear
mkdir -p /boot/new_version
curl -so /boot/initrd.img $Install_Mirror/isolinux/initrd.img
if [ $? -ne '0' ] ;then
  echo -ne "\033[31mError! \033[0mDownload 'initrd.img' failed! \n"
  exit 1
fi
curl -so /boot/vmlinuz $Install_Mirror/isolinux/vmlinuz
if [ $? -ne '0' ];then
  echo -ne "\033[31mError! \033[0mDownload 'vmlinuz' failed! \n"
  exit 1
fi

NewMac=`ip link show $NETDEV |grep link/ether |awk '{print $2}'`

cat >/boot/new_version/ks.cfg<<EOF
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use network installation
url --url="$Install_Mirror"
# Root password
rootpw  $PASSWORD
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use text install
#text
# Use graphical install
graphical
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux --disabled
# Installation logging level
logging --level=info
# Reboot after installation
reboot
# System timezone
timezone Asia/Shanghai --isUtc --nontp
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --driveorder=$BasePart
# Clear the Master Boot Record
zerombr
# Partition clearing information

clearpart --all --initlabel --drives=$ClearDisk
ignoredisk --only-use=$ClearDisk

#clearpart --all --initlabel
#clearpart --linux
# Disk partitioning information
part /boot --fstype="xfs" --asprimary --ondisk=$BootPart --size=$BootSize
part swap --fstype="swap" --ondisk=$SwapPart --size=$SwapSize
part / --fstype="xfs" --ondisk=$BasePart --grow --size=1
%pre
#for i in \`ip addr |grep BROADCAST |awk -F: '{print \$2}'\`;do if [[ \`ip link show \$i |grep \$mac\` != '' ]];then nic=\$i;fi;done
%end
# Network information
network  --bootproto=static --device=$NETDEV --gateway=$GATEWAY --ip=$IPADDR --nameserver=$DNS --netmask=$NETMASK --onboot=on
%post
sed -i -e 's/.*UseDNS.*/UseDNS no/g' -e 's/.*GSSAPIAuthentication.*/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
%end

%packages --nobase
openssh-server
openssh-clients

%end
EOF

[ -f /boot/grub/grub.cfg ] && GRUBOLD='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg'
[ -z $GRUBDIR ] && [ -f /boot/grub2/grub.cfg ] && GRUBOLD='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg'
[ -z $GRUBDIR ] && [ -f /boot/grub/grub.conf ] && GRUBOLD='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf'
[ -z $GRUBDIR -o -z $GRUBFILE ] && echo "Error! Not Found grub path." && exit 1

[ ! -f $GRUBDIR/$GRUBFILE ] && echo "Error! Not Found $GRUBFILE. " && exit 1

[ ! -f $GRUBDIR/$GRUBFILE.old ] && [ -f $GRUBDIR/$GRUBFILE.bak ] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old
if [[  -f $GRUBDIR/$GRUBFILE.bak ]] ; then \cp -p $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE ;fi
mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak
[ -f $GRUBDIR/$GRUBFILE.old ] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE

[ "$GRUBOLD" == '0' ] && {
CFG0="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
CFG2="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)"
CFG1=""
for CFGtmp in `awk '/}/{print NR}' $GRUBDIR/$GRUBFILE`
 do
  [ $CFGtmp -gt "$CFG0" -a $CFGtmp -lt "$CFG2" ] && CFG1="$CFGtmp";
 done
[ -z "$CFG1" ] && {
echo "Error! read $GRUBFILE. "
exit 1
}
sed -n "$CFG0,$CFG1"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
[ -f /tmp/grub.new ] && [ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ] || {
echo -ne "\033[31mError! \033[0mNot configure $GRUBFILE. \n"
exit 1
}

sed -i "/menuentry.*/c\menuentry\ \'Install CentOS\'\  --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ] || {
echo "Error! configure append $GRUBFILE. "
exit 1
}
sed -i "/echo.*Loading/d" /tmp/grub.new
num=`grep -irn "/etc/grub.d/10_linux" $GRUBDIR/$GRUBFILE |grep BEGIN |awk -F: '{print $1}'`
}

[ "$GRUBOLD" == '1' ] && {
CFG0="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
CFG1="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)"
[ -n $CFG0 ] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
[ -n $CFG0 ] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$CFG1"p $GRUBDIR/$GRUBFILE >/tmp/grub.new
[ ! -f /tmp/grub.new ] && echo "Error! configure append $GRUBFILE. " && exit 1
sed -i "/title.*/c\title\ \'Install OS \[$Install_OS\ $OS_Type\]\'" /tmp/grub.new
sed -i '/^#/d' /tmp/grub.new
num=`grep -irn "/etc/grub.d/10_linux" $GRUBDIR/$GRUBFILE |grep BEGIN |awk -F: '{print $1}'`
}

[ -n "$(grep 'initrd.*/' /tmp/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ] && Type='InBoot' || Type='NoBoot'

LinuxKernel="$(grep 'linux.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)"
[ -z $LinuxKernel ] && LinuxKernel="$(grep 'kernel.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)"
LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new |awk '{print $1}' |tail -n 1)"

[ "$Type" == 'InBoot' ] && {
sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/new_version\/vmlinuz ks=hd:$DEVPATH:\/new_version\/ks.cfg" /tmp/grub.new
sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/new_version\/initrd.img" /tmp/grub.new
sed -i "$num r /tmp/grub.new" $GRUBDIR/$GRUBFILE
}

[ "$Type" == 'NoBoot' ] && {
sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz ks=hd:$DEVPATH:\/new_version\/ks.cfg" /tmp/grub.new
sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" /tmp/grub.new
sed -i "$num r /tmp/grub.new" $GRUBDIR/$GRUBFILE
}

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE

grub2-set-default 'Install CentOS'
echo -e "\n\033[36m# Reboot & wait \033[0m\n"
sleep 3 && reboot >/dev/null 2>&1
