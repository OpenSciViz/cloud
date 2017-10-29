#!/bin/sh


# https://whatcloud.wordpress.com/2017/01/09/ose4eg/

$ source keystone_admin
Create the Project (Tenant)

$ openstack project create --description "My First Tenant" FirstTenant
Create a user for the Project

$ openstack user create --password-prompt ftntuser
Give admin rights to admin user on this project:

$ openstack role add --project FirstTenant --user admin admin 
#(Command has no output)
Give user rights to project user on this project:

$ openstack role add --project FirstTenant --user ftntuser user  
#(Command has no output)
In order to list your newly created user:

$ openstack user list 

# Run the following command to create a Public Network called PublicNet:
$ openstack network create PublicNet --provider-network-type flat --provider-physical-network external  --external --share

# Run the following command to create a Subnet under PublicNet called PublicSub:
$ openstack subnet create PublicSub --network PublicNet --subnet-range 172.16.8.0/24 --dhcp --allocation-pool start=172.16.8.130,end=172.16.8.180 --gateway=172.16.8.254

In order to perform the command line configuration we need to source the command line so that it accesses the FirstTenant Project and not the admin project. In order to do this we create a second keystone source file. Use the following procedure to create the source file and source the admin user on the FirstTenant project.

@controller

$ cp ~/keystone_admin ~/keystone_admin_ft 
$ vi ~/keystone_admin_ft 
    export OS_PROJECT_NAME=FirstTenant 
    export PS1='[\u@\h \W(keystone_admin_ft)]$ ' 
$ source ~/keystone_admin_ft
Create the Private Network:

$ openstack network create --provider-network-type vlan --provider-physical-network vlan --provider-segment 1381 FTPrivateNet1
Create the Private Subnet;

$ openstack subnet create FTPrivateSub1 --network FTPrivateNet1 --subnet-range 10.103.81.0/24 --dhcp --gateway=10.103.81.1
Create the tenant Router:

$ openstack router create FTRouter1
Define the Public Network as the external gateway for the router:

$ openstack router set FTRouter1 --external-gateway PublicNet  
# (Gives an Error "openstack router set: error: unrecognized arguments: --external-gateway PublicNet."
# If you get the same error use the command below instead) 
$ neutron router-gateway-set FTRouter1 PublicNet
Finally add an interface from the Private Subnet to the Router:

$ openstack router add subnet FTRouter1 FTPrivateSub1

Source the FirstTenant profile

$ source ~/keystone_admin_ft
Create the Tenant Security Group:

$ openstack security group create FTSecurityGrp1
Assign the ICMP and ssh ingress rules to the security group:

$ openstack security group rule create --ingress --protocol ICMP FTSecurityGrp1 
$ openstack security group rule create --ingress --protocol tcp --dst-port 22 FTSecurityGrp1
Create a ssh keypair (Do NOT forget to make a copy of the private key displayed)

$ openstack keypair create FTKeyPair1
Assign a floating IP to the Project (Not to the instance. That will follow in the next step)

$ openstack floating ip create PublicNet

Source the FirstTenant profile

$ source ~/keystone_admin_ft
T minus 10 seconds to Launch (just run the command below :P):

$ openstack server create --flavor m1.tiny --image cirros --nic net-id=FTPrivateNet1 --security-group FTSecurityGrp1 --key-name FTKeyPair1 FTFirstInstance
In order to confirm that the instance was launched successfully run the following command:

$ openstack server list 

+--------------------------------------+-----------------+--------+----------------------------+------------+ 
| ID                                   | Name            | Status | Networks                   | Image Name | 
+--------------------------------------+-----------------+--------+----------------------------+------------+ 
| 02d1fec3-edbc-4c96-8d2b-a423c4cbcc05 | FTFirstInstance | ACTIVE | FTPrivateNet1=10.103.81.10 | cirros     | 
+--------------------------------------+-----------------+--------+----------------------------+------------+


If you see an output similar to one above where Status = ACTIVE, you have successfully launched your first instance. If not then wait till it turns active.

In order to map a public network (floating IP) to the instance run the following command:

$ openstack floating ip list 
+--------------------------------------+---------------------+------------------+------+ 
| ID                                   | Floating IP Address | Fixed IP Address | Port | 
+--------------------------------------+---------------------+------------------+------+ 
| 8bc8bcd7-11b8-4238-a5cf-c2a4d0d9b77d | 172.16.8.131        | None             | None | 
+--------------------------------------+---------------------+------------------+------+
Your output would be similar (not the same) to the above. Copy the floating IP shown in the output and run the following command using this floating IP.

######################################################

scmId=$Id$
