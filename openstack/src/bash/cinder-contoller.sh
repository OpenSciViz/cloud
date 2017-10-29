#!/bin/sh
# cinder-contoller.sh

echo https://docs.openstack.org//ocata/install-guide-rdo/cinder-controller-install.html

openstack user create --domain default --password-prompt cinder
openstack role add --project service --user cinder admin

openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s

openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s

echo Edit the /etc/cinder/cinder.conf file and complete the following actions:
echo In the [database] section, configure database access:

openstack-config --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:cloud@controller/cinder

echo In the [DEFAULT] section, configure RabbitMQ message queue access:
echo In the [DEFAULT] section, configure the my_ip option to use the management interface IP address of the controller node: 
echo In the [DEFAULT] and [keystone_authtoken] sections, configure Identity service access:

openstack-config --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:cloud@controller
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip 172.17.2.1

openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password cloud

echo Comment out or remove any other options in the [keystone_authtoken] section.

echo in the [oslo_concurrency] section, configure the lock path:
openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

echo Populate the Block Storage database:

echo su -s /bin/sh -c "cinder-manage db sync" cinder

echo Ignore any deprecation messages in this output.
echo Configure Compute to use Block Storage /etc/nova/nova.conf cinder os_region_name RegionOne
echo openstack-config --set /etc/nova/nova.conf cinder os_region_name RegionOne

echo Restart the Compute API service:
# systemctl restart openstack-nova-api.service

echo Start the Block Storage services and configure them to start when the system boots:
# systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl status openstack-nova-api.service openstack-cinder-api.service openstack-cinder-scheduler.service

echo done Cinder block storage config.

######################################################

scmId=$Id$
