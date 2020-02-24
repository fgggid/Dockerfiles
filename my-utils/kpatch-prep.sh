UNAME=3.10.0-957.10.1.el7.x86_64

#sudo yum install gcc kernel-devel-${UNAME%.*} elfutils elfutils-devel
#sudo yum install pesign yum-utils zlib-devel \
#  binutils-devel newt-devel python-devel perl-ExtUtils-Embed \
#  audit-libs audit-libs-devel numactl-devel pciutils-devel bison patchutils

# enable CentOS 7 debug repo
#sudo yum-config-manager --enable debug

sudo yum-builddep kernel-${UNAME%.*}
#sudo debuginfo-install kernel-${UNAME%.*}

# optional, but highly recommended - enable EPEL 7
#sudo yum install ccache
#ccache --max-size=5G
