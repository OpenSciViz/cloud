#!/bin/sh
echo create all the databases:
mysql -f -p < mysql-ocata.sql

echo configure /etc/whatev

grep controller /etc/hosts
if [ $? != 0 ] ; then ech make sure IP for controller host is set; fi

echo backup orig keystone.conf
if [ ! -e /etc/keystone/.keystone.conf ] ; then cp -p /etc/keystone/keystone.conf /etc/keystone/.keystone.conf ; fi

# redhat v11:
# https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/11/html/manual_installation_procedures/sect-configure_the_identity_service
# openstack-config --set /etc/keystone/keystone.conf sql connection mysql://keystone:cloud@controller/keystone

# https://docs.openstack.org//ocata/install-guide-rdo/keystone-install.html
openstack-config --set /etc/keystone/keystone.conf database connection mysql://keystone:cloud@controller/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet

source ./keystone.sh

######################################################

scmId=$Id$
