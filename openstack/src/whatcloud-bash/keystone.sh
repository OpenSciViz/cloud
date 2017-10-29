#!/bin/sh
echo bootstrap the identity service:
echo hopefully the mysql db has been setu via:
su -s /bin/sh -c "keystone-manage db_sync" keystone

echo initialize fernet key repositories:
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password cloud --bootstrap-admin-url http://controller:35357/v3/ --bootstrap-internal-url http://controller:5000/v3/ --bootstrap-public-url http://controller:5000/v3/ --bootstrap-region-id RegionOne

cp -p /etc/httpd/conf/httpd.conf /etc/httpd/conf/.httpd.conf
# this uses crudini, but there is no [section] in the conf file to provide it ...
# openstack-config --set /etc/httpd/conf/httpd.conf section? ServerName controller
# so must hand-edit:
sed 's/www.example.com:80/www.example.com:80\nServerName controller/g' < /etc/httpd/conf/.httpd.conf > /etc/httpd/conf/httpd.conf

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

echo ok start httpd
systemctl start httpd

echo setup roles and users and projects
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password-prompt demo
openstack role create user
openstack role add --project demo --user demo user

# from: https://docs.openstack.org//ocata/install-guide-rdo/keystone-verify.html
# Edit the /etc/keystone/keystone-paste.ini file and remove admin_token_auth from
# the [pipeline:public_api], [pipeline:admin_api], and [pipeline:api_v3] sections.

echo preserve keystone.ini
cp -p /etc/keystone/keystone-paste.ini /etc/keystone/.keystone-paste.ini

unset OS_AUTH_URL OS_PASSWORD

openstack --os-auth-url http://controller:35357/v3 --os-project-domain-name default --os-user-domain-name default --os-project-name admin --os-username admin token issue

echo issue token as demo
source demo-openrc && openstack token issue

echo issue token as admin
source admin-openrc && openstack token issue

######################################################

scmId=$Id$
