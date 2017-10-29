#!/bin/sh

source ./neutron-verify.sh

openstack image list
openstack flavor list

openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

openstack security group list

export NET_ID=4f9a1275-3165-46af-baca-6399925f087f
openstack server create --flavor m4.nano --image atomichost --nic net-id=${NET_ID} --security-group default --key-name ocata-key provider-instance
openstack server list

######################################################

scmId=$Id$
