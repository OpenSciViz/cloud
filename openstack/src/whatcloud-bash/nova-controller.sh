#!/bin/sh

echo https://docs.openstack.org//ocata/install-guide-rdo/nova-controller-install.html

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
cp -p /etc/nova/nova.conf /etc/nova/.nova.conf

echo Configure Compute to use Block Storage /etc/nova/nova.conf cinder os_region_name RegionOne
openstack-config --set /etc/nova/nova.conf cinder os_region_name RegionOne

echo In the [DEFAULT] section, enable only the compute and metadata APIs:
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata

echo In the [DEFAULT] section, configure RabbitMQ message queue access:
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:cloud@controller

echo In the [DEFAULT] section, configure the my_ip option to use the management interface IP address of the controller node:
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip 172.17.2.1

echo In the [DEFAULT] section, enable support for the Networking service:
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

echo In the [api_database] and [database] sections, configure database access:
openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:cloud@controller/nova_api
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://nova:cloud@controller/nova

In the [api] and [keystone_authtoken] sections, configure Identity service access:
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

echo In the [vnc] section, configure the VNC proxy to use the management interface IP address of the controller node:

openstack-config --set /etc/nova/nova.conf keystone_authtoken vnc enabled true
openstack-config --set /etc/nova/nova.conf keystone_authtoken vncserver_listen $my_ip
openstack-config --set /etc/nova/nova.conf keystone_authtoken vncserver_proxyclient_address $my_ip

echo In the [glance] section, configure the location of the Image service API:
openstack-config --set /etc/nova/nova.conf keystone_authtoken glance api_servers http://controller:9292

echo In the [oslo_concurrency] section, configure the lock path:
openstack-config --set /etc/nova/nova.conf keystone_authtoken oslo_concurrency lock_path /var/lib/nova/tmp

echo In the [placement] section, configure the Placement API:
openstack-config --set /etc/nova/nova.conf keystone_authtoken placement os_region_name RegionOne
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357/v3
openstack-config --set /etc/nova/nova.conf keystone_authtoken username placement
openstack-config --set /etc/nova/nova.conf keystone_authtoken password cloud

echo Due to a packaging bug, you must enable access to the Placement API by adding the following
echo configuration to /etc/httpd/conf.d/00-nova-placement-api.conf:

touch /etc/httpd/conf.d/00-nova-placement-api.conf
echo '' >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '<Directory /usr/bin>' >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '   <IfVersion >= 2.4>'  >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '      Require all granted' >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '   </IfVersion>' >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '   <IfVersion < 2.4> >>' /etc/httpd/conf.d/00-nova-placement-api.conf
echo '      Order allow,deny' >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '      Allow from all' >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '   </IfVersion>' >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '</Directory>' >> /etc/httpd/conf.d/00-nova-placement-api.conf
echo '' >> /etc/httpd/conf.d/00-nova-placement-api.conf

echo restart the httpd service:

systemctl restart httpd

echo Populate the nova-api database:
su -s /bin/sh -c "nova-manage api_db sync" nova

echo Register the cell0 database:
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

echo Create the cell1 cell:
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

echo Populate the nova database:
su -s /bin/sh -c "nova-manage db sync" nova

echo Verify nova cell0 and cell1 are registered correctly:
nova-manage cell_v2 list_cells

systemctl start openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

echo all done nova-controller

######################################################

scmId=$Id$
