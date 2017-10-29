#!/bin/sh
openstack network create swarm-public --provider-network-type flat --external --project service
openstack subnet create swarm-public-subnet --network swarm-public --subnet-range 192.168.1.0/24 --gateway 192.168.1.1 --ip-version 4

