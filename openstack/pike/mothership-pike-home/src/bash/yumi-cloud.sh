#/bin/sh
#http://redhatstackblog.redhat.com/2017/01/18/9-tips-to-properly-configure-your-openstack-instance/
df -h

# alias yumi='dnf install -y'
alias yumi='yum install -y'
alias dir='ls -ahlqF'
alias his='history|grep'
alias mkpy='./configure --prefix=/opt/local --enable-shared --with-signal-module --with-fpectl --with-threads --with-ensurepip=install && make'

echo dream devel system
yumi epel-release
yumi ansible gcc gcc-c++ firefox htop git groovy lsof mongodb nodejs nginx unzip zip
yumi curl ipset lokkit nmap ntp rsync tcpdump tcp_wrappers tcp_wrappers-devel traceroute wget vnc xorg-x11-apps
yumi bind-utils bridge-utils net-tools nfs-utils pax-utils yum-utils vconfig 
yumi python-devel python-pip python-imaging ruby-devel db4-devel tcl-devel expat-devel
yumi mysql-server mysql-devel MySQL-python mysql-connector-python PyMySQL SQLAlchemy
yumi bzip2-devel gdbm-devel ncurses-devel openssl-devel readline-devel xz-devel readline-devel 
yumi kernel-devel libxslt-devel libxml2-devel postgresql postgis sqlite-devel

echo KVM
yumi libvirt libvirt-client libvirt-devel libvirt-python libguestfs-tools-c libguestfs-xfs libvirt-python 
yumi qemu qemu-kvm qemu-img qemu-kvm-tools qemu-guest-agent qemu-guest-agent 
yumi virt-install virt-manager virt-viewer 
yumi supermin vagrant

#echo optional cloudstack deps.
#yumi ipmitool jpackage-utils mkisofs mysql-connector-java python-paramiko ws-commons-util

echo SELinux:
yumi selinux-policy selinux-policy-doc policycoreutils-python setroubleshoot setroubleshoot-server

echo openvswitch build dependencies
yumi rpm-build autoconf automake graphviz groff libcap-ng-devel libtool python3-devel selinux-policy-devel 

# 2.7.x openvswitch needs twisted and zope:
# note this includes pyserial
yum install python-twisted-core python-zope-interface

# other useful modules
pip install apache-libcloud flask flask-socketio netaddr pygithub pyinotify pymongo pyroute2 six virtualenv SQLAlchemy

df -h

######################################################

scmId=$Id$
