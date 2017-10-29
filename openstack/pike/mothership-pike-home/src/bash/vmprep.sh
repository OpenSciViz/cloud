#!/bin/sh

# http://libguestfs.org/virt-sysprep.1.html
# http://libguestfs.org/virt-builder.1.html#users-and-passwords
 
qcow=`pwd`/VMs/Fedora-Cloud-Base-26-1.5.x86_64.qcow2

virt-sysprep -a $qcow --root-password password:cloudcloud 
virt-sysprep -a $qcow --password fedora:password:cloudcloud 

# virt-sysprep -a $qcow --firstboot-command 'useradd -m -p "" hon ; chage -d 0 hon'
virt-sysprep -a $qcow --firstboot-command 'useradd -m -p "" hon'

