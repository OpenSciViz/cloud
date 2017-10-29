#!/bin/sh
# sysinit-ocata.sh

systemctl status mariadb.service
systemctl start mariadb.service
# systemctl enable mariadb.service
# mysql_secure_installation
# cat > /etc/my.cnf.d/openstack
#[mysqld]
#bind-address = localhost
#default-storage-engine = innodb
#innodb_file_per_table = on
#max_connections = 4096
#collation-server = utf8_general_ci
#character-set-server = utf8

###

systemctl status rabbitmq-server.service
systemctl start rabbitmq-server.service
# systemctl enable rabbitmq-server.service
# note final arg is user-password ... default to 'cloud' for all ...
# rabbitmqctl add_user openstack cloud 
# rabbitmqctl set_permissions openstack '.*' '.*' '.*'
# redhat v11 also indicates:
# rabbitmqctl add_user cinder cloud
# rabbitmqctl set_permissions cinder '.*' '.*' '.*'
# rabbitmqctl add_user nova cloud
# rabbitmqctl set_permissions nova '.*' '.*' '.*'
# rabbitmqctl add_user neutron cloud
# rabbitmqctl set_permissions neutron '.*' '.*' '.*'
# rabbitmqctl add_user heat cloud
# rabbitmqctl set_permissions heat '.*' '.*' '.*'
# rabbitmqctl add_user glance cloud
# rabbitmqctl set_permissions glance '.*' '.*' '.*'
# rabbitmqctl add_user ceilometer cloud
# rabbitmqctl set_permissions ceilometer '.*' '.*' '.*' 
# redhat v11 also indicates ssl ... echo SSL_RABBITMQ_PWD > /etc/pki/rabbitmq/certpw ... and a bunch of certutil invocations

###

echo setup memcached
# cp -p /etc/sysconfig/memcached /etc/sysconfig/.memcached
# sed 's/OPTIONS/#OPTIONS/g' </etc/sysconfig/.memcached  > /etc/sysconfig/memcached
# echo '#OPTIONS="-l 127.0.0.1,::1,controller"' >> /etc/sysconfig/memcached

systemctl status memcached.service
systemctl start memcached.service
# systemctl enable memcached.service

echo runtime environment is UP!

###

echo setup databases if this is a fresh redux ... ala:
echo mysql -f -p < mysql-ocata.sql

###
echo init keyston identity service ... keystone is a httpd python-django webapp
# source ./keystone.sh


systemctl status httpd
systemctl start httpd

echo to verify keystone is operational, follow this https://docs.openstack.org//ocata/install-guide-rdo/keystone-verify.html

###

echo glance image servce 
# source glance.sh

systemctl status openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

echo nova compute services
systemctl status openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl status libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

echo conder block storage services
systemctl status openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service

######################################################

scmId=$Id$
