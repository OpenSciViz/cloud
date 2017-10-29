#!/bin/sh

qcow=no-initCentOS-7-x86_64-GenericCloud-1708

#echo set root password and create hon account
#virt-sysprep -a ${qcow}.qcow2 --root-password password:cloudcloud
#virt-sysprep -a ${qcow}.qcow2 --firstboot-command 'useradd -m -p "cloud" hon'

vcpu=2
vram=2048
vname=${vcpu}cpu-${qcow}
bridge=ovsbr1

virt-install --import --noautoconsole --cpu host --connect qemu:///system --ram=${vram} --name=${vname} --vcpus=${vcpu} \
--network=network:${bridge} --network=network:${bridge} \
--os-type=linux --os-variant=rhel7 --disk path=${qcow}.qcow2,device=disk,bus=virtio,format=qcow2

