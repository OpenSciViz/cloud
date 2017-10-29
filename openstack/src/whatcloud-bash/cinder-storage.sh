#!/bin/sh

echo assume /dev/vdb exists:
echo virsh attach-device ovsstack-64g-centos7-ram16384-cpu8 ./vdb.xml
# contents of vdb.xml
# <disk type='file' device='disk'>
#   <driver name='qemu' type='raw' cache='none'/>
#   <source file='/home/hon/jul2017/openstack/ovsstack/vdbCentOS-7-CinderLVM.qcow2v3'/>
#   <target dev='vdb'/>
# </disk>

echo In the /etc/lvm/lvm.conf devices section, add a filter that accepts the /dev/vdb device and rejects all other devices:

# devices {
# filter = [ "a/vdb/", "r/.*/"]

# If your storage nodes use LVM on the operating system disk, you must also add the associated device to the filter. For example, if the /dev/sda device contains the operating system:
# filter = [ "a/sda/", "a/sdb/", "r/.*/"]
#Similarly, if your compute nodes use LVM on the operating system disk, you must also modify the filter in the /etc/lvm/lvm.conf file on those nodes to include only the operating system disk. For example, if the /dev/sda device contains the operating system:
#filter = [ "a/sda/", "r/.*/"]

# systemctl restart lvm2-lvmetad.service

# assume /dev/vdb has been unmounted?
# Create the LVM physical volume /dev/vdb:
# pvcreate /dev/vdb

# Create the LVM volume group cinder-volumes:
# vgcreate cinder-volumes /dev/vdb1

# configure LVM to scan only the devices that contain the cinder-volumes volume group. Edit the /etc/lvm/lvm.conf file and complete the following actions:

echo Edit the /etc/cinder/cinder.conf file and complete the following actions:
echo In the [database] section, configure database access:
openstack-config --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:cloud@controller/cinder

echo  In the [DEFAULT] section, configure RabbitMQ message queue access:
openstack-config --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:cloud@controller

echo In the [DEFAULT] section, configure the my_ip option:
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken DEFAULT my_ip 172.17.2.1

echo In the [DEFAULT] section, enable the LVM back end:
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends lvm

echo Back-end names are arbitrary. As an example, this guide uses the name of the driver as the name of the back end.
echo In the [DEFAULT] section, configure the location of the Image service API:
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://controller:9292

echo In the [DEFAULT] and [keystone_authtoken] sections, configure Identity service access:
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url = http://controller:35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password cloud

echo Comment out or remove any other options in the [keystone_authtoken] section.

echo In the [lvm] section, configure the LVM back end with the LVM driver, cinder-volumes volume group, iSCSI protocol, and appropriate iSCSI service. If the [lvm] section does not exist, create it:

openstack-config --set /etc/cinder/cinder.conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
openstack-config --set /etc/cinder/cinder.conf lvm volume_group cinder-volumes
openstack-config --set /etc/cinder/cinder.conf lvm iscsi_protocol iscsi
openstack-config --set /etc/cinder/cinder.conf lvm iscsi_helper lioadm

echo In the [oslo_concurrency] section, configure the lock path:
openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

echo Start the Block Storage volume service including its dependencies and configure them to start when the system boots:

# systemctl start openstack-cinder-volume.service target.service
# systemctl status openstack-cinder-volume.service target.service

######################################################

scmId=$Id$
