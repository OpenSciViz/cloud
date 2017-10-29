#!/bin/sh
yumi='yum install -y'

function dev-install {
  echo yum all essential devel packages
  $yumi python-devel openssl-devel mysql-devel libxml2-devel libxslt-devel postgresql-devel git libffi-devel gettext gcc
}

function pike-install {
  echo yum all essential pike packages

  $yumi centos-release-openstack-pike
  $yumi chrony
  $yumi mariadb mariadb-server python2-PyMySQL
  $yumi rabbitmq-server
  $yumi memcached python-memcached
  $yumi httpd mod_wsgi
  $yumi lvm2 targetcli
  $yumi ebtables ipset

  # nested virtualization VMs will need:
  $yumi virt-install libvirt-python virt-manager virt-install libvirt-client

  $yumi openstack-selinux
  $yumi python-openstackclient openstack-utils
  $yumi openstack-keystone python-keystone
  $yumi openstack-glance
  $yumi openstack-cinder 

  $yumi openstack-nova-scheduler openstack-nova-placement-api openstack-nova-compute
  $yumi openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy

  # with or without legacy linux bridge agent
  # $yumi openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
  $yumi openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch openstack-neutron-linuxbridge

  $yumi openstack-dashboard

  $yumi openstack-heat-api openstack-heat-api-cfn openstack-heat-engine

  $yumi openstack-magnum-api openstack-magnum-conductor python-magnumclient

  # yum update / upgrade wants to install openvswitch 2.6.1 ... replacing our 2.7.2 ... no thanks
  # yum update -x '*openvswitch*'
  yum update 
}

function pike-remove {
# remove these in reverse order of install?
  yum remove python-openstackclient openstack-utils
  yum remove openstack-keystone python-keystone
  yum remove openstack-glance
  yum remove openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy
  yum remove openstack-nova-scheduler openstack-nova-placement-api openstack-nova-compute
  yum remove lvm2
  yum remove openstack-cinder targetcli
  yum remove openstack-neutron openstack-neutron-ml2 ebtables ipset
  yum remove openstack-neutron-openvswitch
# yum remove openstack-neutron-linuxbridge
  yum remove openstack-dashboard
}

function pike-etc {
  \ls -alqF /etc/{cinder,glance,heat,httpd,keystone,lvm,magnum,my.cnf,my.cnf.d,neutron,nova,rabbitmq}
}

dev-install -v
pike-etc


######################################################

scmId=$Id$
