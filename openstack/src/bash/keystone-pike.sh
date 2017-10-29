#!/bin/sh

#Populate the Identity service database:

echo start keystone db_sync and fernet_setup and bootstrap
time su -s /bin/sh -c "keystone-manage db_sync" keystone

echo Initialize Fernet key repositories:

time keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
time keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

echo Bootstrap the Identity service:

time keystone-manage bootstrap --bootstrap-password cloud \
--bootstrap-admin-url http://controller:35357/v3/ \
--bootstrap-internal-url http://controller:5000/v3/ \
--bootstrap-public-url http://controller:5000/v3/ \
--bootstrap-region-id RegionOne

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

pushd /etc/pike/httpd
mv logs .logs
ln -s /var/log/httpd logs
mv modules .modules
ln -s /usr/lib64/httpd/modules
popd

systemctl restart httpd.service

echo before testing token requests, be sure to setup authorization using funcs in authsetup-pike.sh
echo . authsetup-pike.sh

echo Unset the temporary OS_AUTH_URL and OS_PASSWORD environment variable:

unset OS_AUTH_URL OS_PASSWORD
echo As the admin user, request an authentication token:

openstack --os-auth-url http://controller:35357/v3 \
--os-project-domain-name Default --os-user-domain-name Default \
--os-project-name admin --os-username admin token issue

echo As the demo user, request an authentication token:

openstack --os-auth-url http://controller:5000/v3 \
--os-project-domain-name Default --os-user-domain-name Default \
--os-project-name demo --os-username demo token issue
