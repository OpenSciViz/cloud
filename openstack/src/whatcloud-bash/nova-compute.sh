#!/bin/sh
echo https://docs.openstack.org//ocata/install-guide-rdo/nova-compute-install.html

openstack user create --domain default --password-prompt nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1
openstack user create --domain default --password-prompt placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

echo Edit the /etc/nova/nova.conf file and complete the following actions:
echo In the [DEFAULT] section, enable only the compute and metadata APIs:
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata

echo In the [DEFAULT] section, configure RabbitMQ message queue access:
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:cloud@controller

echo In the [DEFAULT] section, configure the my_ip option:
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip 172.17.2.1

echo In the [DEFAULT] section, enable support for the Networking service:
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

echo In the [api] and [keystone_authtoken] sections, configure Identity service access:
openstack-config --set /etc/nova/nova.conf api auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password cloud

echo Comment out or remove any other options in the [keystone_authtoken] section.

In the [vnc] section, enable and configure remote console access:

openstack-config --set /etc/nova/nova.conf vnc enabled True
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $my_ip
penstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://controller:6080/vnc_auto.html

echo The server component listens on all IP addresses and the proxy component only listens on the
echo management interface IP address of the compute node. The base URL indicates the location where
echo you can use a web browser to access remote consoles of instances on this compute node.

echo If the web browser to access remote consoles resides on a host that cannot resolve the controller
echo hostname, you must replace controller with the management interface IP address of the controller node.

echo In the [glance] section, configure the location of the Image service API:
openstack-config --set /etc/nova/nova.conf glance api_servers http://controller:9292

echo In the [oslo_concurrency] section, configure the lock path:
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

echo In the [placement] section, configure the Placement API:

openstack-config --set /etc/nova/nova.conf placement os_region_name RegionOne
openstack-config --set /etc/nova/nova.conf placement project_domain_name default
openstack-config --set /etc/nova/nova.conf placement project_name service
openstack-config --set /etc/nova/nova.conf placement auth_type password
openstack-config --set /etc/nova/nova.conf placement user_domain_name default
openstack-config --set /etc/nova/nova.conf placement auth_url http://controller:35357/v3
openstack-config --set /etc/nova/nova.conf placement username placement
openstack-config --set /etc/nova/nova.conf placement password cloud

echo When you add new compute nodes, you must run nova-manage cell_v2 discover_hosts on the controller node to
register those new compute nodes. Alternatively, you can set an appropriate interval in /etc/nova/nova.conf:

openstack-config --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300

# systemctl status libvirtd.service openstack-nova-compute.service
# systemctl start libvirtd.service openstack-nova-compute.service

echo all done nova-compute config.

###

echo test verify nova-compute

openstack hypervisor list
openstack compute service list
openstack catalog list
openstack image list

######################################################

scmId=$Id$
