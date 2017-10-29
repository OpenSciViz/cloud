# yum install chrony

2. Edit the /etc/chrony.conf file and add, change, or remove these keys as necessary for your environment:
--
# yum install chrony

2. Edit the /etc/chrony.conf file and comment out or remove all but one server key. Change it to
--
backwards compatibility. Or, preferably pin package versions using the yum-versionlock plugin.

Note: The following steps apply to RHEL only. CentOS does not require these steps.
--
# yum install centos-release-openstack-ocata

• On RHEL, download and install the RDO repository RPM to enable the OpenStack repository.
# yum install https://rdoproject.org/repos/rdo-release.rpm

Finalize the installation
--
# yum upgrade

Note: If the upgrade process includes a new kernel, reboot your host to activate it.
--
# yum install python-openstackclient

3. RHEL and CentOS enable SELinux by default. Install the openstack-selinux package to automatically manage security policies for OpenStack services:
# yum install openstack-selinux

SQL database
--
# yum install mariadb mariadb-server python2-PyMySQL

2. Create and edit the /etc/my.cnf.d/openstack.cnf file and complete the following actions:
--
# yum install rabbitmq-server

2. Start the message queue service and configure it to start when the system boots:
--
# yum install memcached python-memcached

2. Edit the /etc/sysconfig/memcached file and complete the following actions:
--
# yum install openstack-keystone httpd mod_wsgi

2. Edit the /etc/keystone/keystone.conf file and complete the following actions:
--
# yum install openstack-glance

2. Edit the /etc/glance/glance-api.conf file and complete the following actions:
--
# yum install openstack-nova-api openstack-nova-conductor \
openstack-nova-console openstack-nova-novncproxy \
openstack-nova-scheduler openstack-nova-placement-api
--
# yum install openstack-nova-compute

2. Edit the /etc/nova/nova.conf file and complete the following actions:
--
# yum install openstack-neutron openstack-neutron-ml2 \
openstack-neutron-linuxbridge ebtables

--
# yum install openstack-neutron openstack-neutron-ml2 \
openstack-neutron-linuxbridge ebtables

--
# yum install openstack-neutron-linuxbridge ebtables ipset

Configure the common component
--
# yum install openstack-dashboard

2. Edit the /etc/openstack-dashboard/local_settings file and complete the following actions:
--
# yum install openstack-cinder

2. Edit the /etc/cinder/cinder.conf file and complete the following actions:
--
# yum install lvm2

• Start the LVM metadata service and configure it to start when the system boots:
--
# yum install openstack-cinder targetcli python-keystone

2. Edit the /etc/cinder/cinder.conf file and complete the following actions:

######################################################

scmId=$Id$
