#!/bin/sh
openstack extension list --network
openstack network agent list

openstack network list
brctl show

openstack network create --share --external --provider-physical-network provider --provider-network-type flat provider
openstack subnet create --network provider --allocation-pool start=172.17.2.100,end=172.17.2.200 --dns-nameserver 8.8.8.8 --gateway 172.17.2.1 --subnet-range 172.16.0.0/12 provider

openstack network list
openstack network show provider
brctl show

######################################################

scmId=$Id$
