#!/bin/sh
# open-stack indicates one should disable NetworkManager and enable iptables
systemctl stop NetworkManager
systemctl disable NetworkManager

systemctl enable iptables
systemctl start iptables

systemctl enable libvirtd
systemctl start libvirtd

# enable nested virtualization
# https://wiki.archlinux.org/index.php/KVM
lscpu | grep -i virtualization
lsmod |grep kvm
echo 'options kvm_intel nested=1' >> /etc/modprobe.d/kvm_intel.conf
modprobe -r kvm_intel
modprobe kvm_intel nested=1
systool -m kvm_intel -v | grep nested

# for VM tools and docker and perhaps openstack
yum install -y yum-utils device-mapper-persistent-data lvm2
yum install libguestfs-tools
yum makecache fast
grep keep /etc/yum.conf /dev/null
echo make sure keepcache=1 in yum.conf

# openstack pike RPMs
source ./yumi-pike.sh

# docker and swarm
# https://docs.docker.com/engine/installation/linux/docker-ce/centos/#uninstall-docker-ce
yum remove docker docker-common docker-selinux docker-engine
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce

# systemctl enable docker
# systemctl start docker

