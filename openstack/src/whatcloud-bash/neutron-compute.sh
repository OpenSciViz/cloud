#!/bin/sh
echo neutron-compute ... is a subset of neutron-contoller ... so this can be skipped on the controller ...

Edit the /etc/neutron/neutron.conf file and complete the following actions:

In the [database] section, comment out any connection options because compute nodes do not directly access the database.

In the [DEFAULT] section, configure RabbitMQ message queue access:

[DEFAULT]
# ...
transport_url = rabbit://openstack:RABBIT_PASS@controller
Replace RABBIT_PASS with the password you chose for the openstack account in RabbitMQ.

In the [DEFAULT] and [keystone_authtoken] sections, configure Identity service access:

[DEFAULT]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS
Replace NEUTRON_PASS with the password you chose for the neutron user in the Identity service.

 Note

Comment out or remove any other options in the [keystone_authtoken] section.
In the [oslo_concurrency] section, configure the lock path:

[oslo_concurrency]
# ...
lock_path = /var/lib/neutron/tmp

######################################################

scmId=$Id$
