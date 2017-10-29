 openstack compute service list
 openstack extension list --network
 openstack flavor list
 openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
 openstack flavor create --id 1 --vcpus 1 --ram 64 --disk 4 m4.nano
 openstack flavor list
 openstack hypervisor list
 openstack image list
 openstack keypair list
 openstack keypair create --public-key ~/.ssh/id_rsa.pub ocata-key
 openstack network agent list
 openstack network create --share --external --provider-physical-network provider --provider-network-type flat provider
 openstack network delete provider
 openstack network list
 openstack network show provider
 openstack security group list
 openstack security group rule create --proto icmp default
 openstack security group rule create --proto tcp --dst-port 22 default
 openstack server create --flavor m4.nano --image atomichost --nic net-id=${SELFSERVICE_NET_ID} --security-group default --key-name ocata-key provider-instance
 openstack server create --flavor m4.nano --image atomichost --nic net-id=${SELFSERVICE_NET_ID} --security-group --key-name ocata-key default provider-instance
 openstack server list
 openstack subnet create --network provider --allocation-pool start=172.17.2.100,end=172.17.2.200 --dns-nameserver 8.8.8.8 --gateway 172.17.2.1 --subnet-range 172.16.0.0/12 provider

######################################################

scmId=$Id$
