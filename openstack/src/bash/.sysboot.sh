#!/bin/sh

invoke=$_
string="$0"

echo sysboot.sh ... \"$invoke\" and \"$string\"

subshell=${string//[-._]/}
echo "subshell == $subshell"

if [ "$subshell" != "bash" ]; then
  echo "$invoke" must be sourced
  echo try: \"'. '${invoke}\" ... or: \"source ${invoke}\"
  exit 
fi

# https://docs.openstack.org/ocata/networking-guide/deploy.html#mechanism-drivers
# https://docs.openstack.org/ocata/networking-guide/deploy-ovs.html

# The Open vSwitch (OVS) mechanism driver uses a combination of OVS and Linux bridges as interconnection devices.
# However, optionally enabling the OVS native implementation of security groups removes the dependency on Linux bridges.

# presumablye if we don't use any linux-bridges, need to establish some iptables rules for OVS -- is this it:
# https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/11/html/manual_installation_procedures/sect-configure_the_networking_service#Configuring_the_Firewall4

# source ./admin-openrc

export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=cloud
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

env| egrep 'BASH|OS_'

function ocata-list {
 openstack compute service list
 openstack extension list --network
 openstack flavor list
 openstack hypervisor list
 openstack image list
 openstack keypair list
 openstack network agent list
 openstack network list
 openstack security group list
 openstack server list
}

function ocata-verify {
  systemctl status openstack-nova-compute.service >& /dev/null
  if [ $? == 0 ] ; then
    ocata-list
  else
    echo Ocata Openstack services are not up.
  fi
  ovs-vsctl show
}

function ocata-status {
  systemctl status iptables.service
  systemctl status mariadb.service
  systemctl status rabbitmq-server.service
  systemctl status memcached.service
  systemctl status httpd
  systemctl status libvirtd.service
  systemctl status lvm2-lvmetad.service
  systemctl status openvswitch.service

  systemctl status openstack-cinder-api.service openstack-cinder-scheduler.service
  systemctl status openstack-cinder-volume.service target.service
  systemctl status openstack-glance-api.service openstack-glance-registry.service

  systemctl status openstack-nova-api.service openstack-nova-consoleauth.service 
  systemctl status openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
  systemctl status openstack-nova-compute.service

  systemctl status neutron-openvswitch-agent
  systemctl status neutron-ovs-cleanup.service
  systemctl status neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service
  systemctl status neutron-l3-agent.service
  systemctl status neutron-linuxbridge-agent.service 

  ovs-vsctl show
}

function ocata-startup {
  echo presumably OVS has been started at boot, but if not:
  # systemctl status openvswitch.service
  systemctl start mariadb.service
  systemctl start rabbitmq-server.service
  systemctl start memcached.service
  systemctl start httpd

  systemctl start openstack-glance-api.service openstack-glance-registry.service

  systemctl start openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
  systemctl start libvirtd.service openstack-nova-compute.service

  systemctl start neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service
# systemctl start neutron-linuxbridge-agent.service 
  systemctl start neutron-openvswitch-agent
  systemctl start neutron-ovs-cleanup.service
  systemctl start neutron-l3-agent.service

  systemctl start lvm2-lvmetad.service
  systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
  systemctl start openstack-cinder-volume.service target.service

  ocata-verify -v
}

function ocata-shutdown {
  echo assuming NICs are attache OVS bridges, so DO NOT shutdown openvswtich ...
  systemctl stop openstack-cinder-volume.service target.service
  systemctl stop openstack-cinder-api.service openstack-cinder-scheduler.service
  systemctl stop lvm2-lvmetad.service

  systemctl stop neutron-l3-agent.service
  systemctl stop neutron-ovs-cleanup.service
  systemctl stop neutron-openvswitch-agent
# systemctl stop neutron-linuxbridge-agent.service 
  systemctl stop neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service

  systemctl stop libvirtd.service openstack-nova-compute.service
  systemctl stop openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
  systemctl stop openstack-glance-api.service openstack-glance-registry.service

  systemctl stop httpd
  systemctl stop memcached.service
  systemctl stop rabbitmq-server.service
  systemctl stop mariadb.service
}

if [[ $1 == up ]] ; then ocata-startup ; fi
if [[ $1 == down ]] ; then ocata-shutdown ; fi

systemctl status openstack-nova-compute.service >& /dev/null
if [ $? == 0 ] ; then
  ocata-status -v
else
  echo Ocata Openstack services are currently inactive ...
fi
 
