#!/bin/sh

function ocata-install {
  echo yum all essential ocata packages
  yum install centos-release-openstack-ocata
  yum install chrony
  yum install mariadb mariadb-server python2-PyMySQL
  yum install rabbitmq-server
  yum install memcached python-memcached
  yum install httpd mod_wsgi
  yum install openstack-selinux
  yum install python-openstackclient openstack-utils
  yum install openstack-keystone python-keystone
  yum install openstack-glance
  yum install lvm2
  yum install openstack-cinder targetcli
  yum install openstack-dashboard
  yum install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api openstack-nova-compute
  yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge openstack-neutron-openvswitch ebtables ipset

  # yum update / upgrade wants to install openvswitch 2.6.1 ... replacing our 2.7.2 ... no thanks
  # yum update -x '*openvswitch*'
  yum update 
}

function ocata-remove {
  yum remove openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge openstack-neutron-openvswitch ebtables ipset
  yum remove openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api openstack-nova-compute
  yum remove openstack-dashboard
  yum remove openstack-cinder targetcli
  yum remove lvm2
  yum remove openstack-glance
  yum remove openstack-keystone python-keystone
  yum remove python-openstackclient openstack-utils
}

function ocata-etc {
  \ls -alqF /etc/{cinder,httpd,keystone,my.cnf,my.cnf.d,neutron,nova,rabbitmq}
}

function ocata-symlnk-etc {
  pushd /etc
  ln -s ocata-aug2017-whatcloud/cinder
  ln -s ocata-aug2017-whatcloud/glance
  ln -s ocata-aug2017-whatcloud/httpd
  ln -s ocata-aug2017-whatcloud/keystone
  ln -s ocata-aug2017-whatcloud/my.cnf
  ln -s ocata-aug2017-whatcloud/my.cnf.d
  ln -s ocata-aug2017-whatcloud/neutron
  ln -s ocata-aug2017-whatcloud/nova
  ln -s ocata-aug2017-whatcloud/rabbitmq
  popd
}

echo ocata-remove and ocata-install ocata-symlnk-etc
ocata-etc

######################################################

scmId=$Id$
