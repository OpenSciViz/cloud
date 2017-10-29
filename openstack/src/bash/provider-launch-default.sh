#!/bin/sh

# https://docs.openstack.org/install-guide/launch-instance-networks-provider.html
# source ./admin-openrc

export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=cloud
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

echo Create the network
openstack network create --share --external --provider-physical-network provider --provider-network-type flat provider

echo Create a subnet on the network:
openstack subnet create --network provider --allocation-pool start=192.168.122.230,end=192.168.122.250 --dns-nameserver 8.8.4.4 --gateway 192.168.122.1 --subnet-range 192.168.122.0/24 provider


# openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
openstack keypair list
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
openstack flavor list
openstack image list
openstack network list

openstack project list
#+----------------------------------+---------+
#| ID                               | Name    |
#+----------------------------------+---------+
#| 272c10985cc649f3b1504b6a85fbe6ee | hon     |
#| 33dc53eb24a349c1886251869a263d60 | admin   |
#| dbfe68420e044b7285261ff0b15e0926 | service |
#| edd3797372aa47f384c86d3a9b30c702 | demo    |
#+----------------------------------+---------+

openstack security group list
#+--------------------------------------+---------+------------------------+----------------------------------+
#| ID                                   | Name    | Description            | Project                          |
#+--------------------------------------+---------+------------------------+----------------------------------+
#| 03ef92d6-a887-47c5-8d08-0cc054736053 | default | Default security group | 33dc53eb24a349c1886251869a263d60 |
#| 93b9522a-c68a-4674-9165-793f11852b2c | default | Default security group | dbfe68420e044b7285261ff0b15e0926 |
#+--------------------------------------+---------+------------------------+----------------------------------+

openstack server list
openstack server create --flavor m1.nano --image cirros --nic net-id=provider --security-group 03ef92d6-a887-47c5-8d08-0cc054736053 --key-name mykey admin-provider-instance
openstack server list

# try this ... hum perhaps this fails cause we are using admin authentication, not service ...
openstack security group rule create --proto icmp 93b9522a-c68a-4674-9165-793f11852b2c
openstack security group rule create --proto tcp --dst-port 22 93b9522a-c68a-4674-9165-793f11852b2c
openstack server create --flavor m1.nano --image cirros --nic net-id=provider --security-group 93b9522a-c68a-4674-9165-793f11852b2c --key-name mykey service-provider-instance
openstack server list

dir /var/lib/nova/instances/
dir /var/lib/nova/instances/223f21ea-8c3f-4a41-bd62-212f638d7bba/
cat /var/lib/nova/instances/223f21ea-8c3f-4a41-bd62-212f638d7bba/console.log

virsh list
virsh console instance-00000001 --devname serial1

# openstack subnet create --network provider \
# --allocation-pool start=START_IP_ADDRESS,end=END_IP_ADDRESS \
# --dns-nameserver DNS_RESOLVER --gateway PROVIDER_NETWORK_GATEWAY \
# --subnet-range PROVIDER_NETWORK_CIDR provider

# Replace PROVIDER_NETWORK_CIDR with the subnet on the provider physical network in CIDR notation.

# Replace START_IP_ADDRESS and END_IP_ADDRESS with the first and last IP address of the range within the subnet that you want to allocate for instances. This range must not include any existing active IP addresses.

# Replace DNS_RESOLVER with the IP address of a DNS resolver. In most cases, you can use one from the /etc/resolv.conf file on the host.

# Replace PROVIDER_NETWORK_GATEWAY with the gateway IP address on the provider network, typically the “.1” IP address.

# Example

# The provider network uses 203.0.113.0/24 with a gateway on 203.0.113.1. A DHCP server assigns each instance an IP address from 203.0.113.101 to 203.0.113.250. All instances use 8.8.4.4 as a DNS resolver.
# openstack subnet create --network provider \
#  --allocation-pool start=203.0.113.101,end=203.0.113.250 \
#  --dns-nameserver 8.8.4.4 --gateway 203.0.113.1 \
#  --subnet-range 203.0.113.0/24 provider


