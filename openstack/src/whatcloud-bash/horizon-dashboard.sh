#!/bin/sh

echo Edit the /etc/openstack-dashboard/local_settings file and complete the following actions:
echo Configure the dashboard to use OpenStack services on the controller node:

echo OPENSTACK_HOST = "controller"
echo Allow your hosts to access the dashboard:

ALLOWED_HOSTS = ['one.example.com', 'two.example.com']
ALLOWED_HOSTS can also be [‘*’] to accept all hosts. 

echo See https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts for further information.

echo Configure the memcached session storage service:

SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}
 Note

Comment out any other session storage configuration.
Enable the Identity API version 3:

OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
Enable support for domains:

OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
Configure API versions:

OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
Configure Default as the default domain for users that you create via the dashboard:

OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
Configure user as the default role for users that you create via the dashboard:

OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
If you chose networking option 1, disable support for layer-3 networking services:

OPENSTACK_NEUTRON_NETWORK = {
    ...
    'enable_router': False,
    'enable_quotas': False,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_lb': False,
    'enable_firewall': False,
    'enable_vpn': False,
    'enable_fip_topology_check': False,
}
Optionally, configure the time zone:

TIME_ZONE = "TIME_ZONE"
Replace TIME_ZONE with an appropriate time zone identifier. For more information, see the list of time zones.

systemctl restart httpd.service memcached.service

scmId=$Id$

######################################################

scmId=$Id$
