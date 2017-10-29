#!/bin/sh

# https://ask.openstack.org/en/question/48264/deactivate-security-groups/
# You can create a security group that permits all traffic. E.g., using Neutron:

neutron security-group-create all_open
neutron security-group-rule-create --protocol icmp all_open
neutron security-group-rule-create --protocol tcp all_open
neutron security-group-rule-create --protocol udp all_open

