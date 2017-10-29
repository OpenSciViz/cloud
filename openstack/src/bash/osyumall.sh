yum install chrony
yum install centos-release-openstack-ocata
# yum install https://rdoproject.org/repos/rdo-release.rpm
yum upgrade

echo Note: If the upgrade process includes a new kernel, reboot your host to activate it.
yum install python-openstackclient

yum install openstack-selinux

echo SQL database
yum install mariadb mariadb-server python2-PyMySQL
echo Create and edit the /etc/my.cnf.d/openstack.cnf file and complete the following actions:

yum install rabbitmq-server
echo Start the message queue service and configure it to start when the system boots:

yum install memcached python-memcached
echo Edit the /etc/sysconfig/memcached file and complete the following actions:

yum install openstack-keystone httpd mod_wsgi
echo Edit the /etc/keystone/keystone.conf file and complete the following actions:

yum install openstack-glance
echo Edit the /etc/glance/glance-api.conf file and complete the following actions:

# yum install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api install openstack-nova-compute
echo Edit the /etc/nova/nova.conf file and complete the following actions:

yum install lvm2
echo Start the LVM metadata service and configure it to start when the system boots:

yum install openstack-cinder targetcli python-keystone
echo Edit the /etc/cinder/cinder.conf file and complete the following actions:

yum install openstack-dashboard
echo Edit the /etc/openstack-dashboard/local_settings file and complete the following actions:

echo neutron linux-bridges is deprecated ... use openvswitch
# yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ebtables ipset

######################################################

scmId=$Id$
