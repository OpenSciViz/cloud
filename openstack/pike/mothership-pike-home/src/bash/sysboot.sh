#!/bin/sh

invoke=$_
string="$0"
#echo sysboot.sh ... \"$invoke\" and \"$string\"

echo any change to the system controller IP must be propogated in:
echo /etc/hosts /etc/heat/heat.conf /etc/nova/nova.conf my.cnf.d/openstack.cnf /etc/cinder/cinder.conf 

subshell=${string//[-._]/}
# echo "subshell == $subshell"

if [ "$subshell" != "bash" ]; then
  echo "$invoke" must be sourced
  echo try: \"'. '${invoke}\" ... or: \"source ${invoke}\"
  exit
fi

# https://docs.openstack.org/pike/networking-guide/deploy.html#mechanism-drivers
# https://docs.openstack.org/pike/networking-guide/deploy-ovs.html

# The Open vSwitch (OVS) mechanism driver uses a combination of OVS and Linux bridges as interconnection devices.
# However, optionally enabling the OVS native implementation of security groups removes the dependency on Linux bridges.

# presumablye if we don't use any linux-bridges, need to establish some iptables rules for OVS -- is this it:
# https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/11/html/manual_installation_procedures/sect-configure_the_networking_service#Configuring_the_Firewall4

# source ./admin-openrc

export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
#export OS_PASSWORD=cloud
export OS_PASSWORD=oct2017cloud
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

env| egrep 'BASH|OS_'

allpike='cinder glance horizon httpd libvirt/qemu mariadb neutron nova openvswitch qemu-ga rabbitmq'
other='/var/log/cloud-init.log'

function pike-logs {
# today=`date "+%Y/%j/%H/%M/"`
  today=`date "+%Y/%j/%H/"`
  echo $today $allpike
  backups=/backup/varlog/${today}
  echo backups at $backups
  for l in $allpike ; do
    logs=/var/log/$l
    \ls -alhqF $logs
    if [ $? == 0 ] ; then 
      egrep -i 'abor|err|excep|fatal|warn' ${logs}/* | tail -20 | tee -a pikelogs.txt
      \ls -alhqF ${logs}/* | tee -a pikelogs.txt 
      if [[ $1 == -t ]] ; then 
        \tail -f ${logs}/* &
        \jobs
      fi
      if [[ $1 == -b ]] ; then
        \mkdir -p $backups 
        \rsync -val $logs $backups
        \ls -alhqF ${backups}/$l
        if [[ $2 == -d ]] ; then 
          echo clearing logs in /var/log ... backups can be found in $backups
          truncate -s 0 ${logs}/*
          \ls -alhqF ${logs}/*
        fi
      fi
    fi
  done
  if [[ $1 == -b ]] ; then \ls -alhqFR $backups ; fi
}

function pike-compute-list {
# https://docs.openstack.org/nova/pike/admin/availability-zones.html
  echo ==================================== show Pike Compute Lists ============================================================
  echo openstack compute service list ; openstack compute service list
  echo ===========================================================================================================================
  echo openstack image list ; openstack image list
  echo ===========================================================================================================================
  echo openstack availability zone list ; openstack availability zone list
  echo openstack host list ; openstack host list
  echo openstack hypervisor list ; openstack hypervisor list ; echo each hypervisor is a node ... i think
  echo ===========================================================================================================================
  echo openstack flavor list ; openstack flavor list
  echo ===========================================================================================================================
  echo openstack server list ; openstack server list
  echo ==================================== done Pike Compute Lists ============================================================
}

function pike-network-list {
  echo ==================================== show Pike Network Lists ============================================================
  echo openstack extension list --network ; openstack extension list --network
  echo ===========================================================================================================================
  echo openstack network agent list ; openstack network agent list
  echo ===========================================================================================================================
  echo openstack network list ; openstack network list
  echo ===========================================================================================================================
  echo openstack subnet list ; openstack subnet list
  echo ==================================== done Pike Network Lists =============================================================
}

function pike-list {
  echo ==================================== show Pike System Status Lists ======================================================

  echo openstack security group list ; openstack security group list
  echo ===========================================================================================================================
  echo openstack user list ; openstack user list 
  echo ===========================================================================================================================
  echo openstack keypair list ; openstack keypair list

  pike-network-list -v
  pike-compute-list -v



  openstack orchestration template version list
  openstack stack list

  magnum service-list

  echo ==================================== done Pike System Status Lists =======================================================
}

function pike-verify {
  echo verify openstack services are up ...
  systemctl status openstack-nova-compute.service >& /dev/null
  if [ $? == 0 ] ; then
    pike-list
  else
    echo Pike Openstack services are not up.
  fi
  ovs-vsctl show
  brctl show
}

function heat-status {
  systemctl status openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
  if [ $? == 0 ] ; then
    openstack orchestration service list
  else
    Heat orchestration services not up ...
  fi
}

function pike-status {
  systemctl status iptables.service
  systemctl status mariadb.service
  systemctl status rabbitmq-server.service
  systemctl status memcached.service
  systemctl status httpd
  systemctl status libvirtd.service
  systemctl status lvm2-lvmetad.service
# systemctl status openvswitch.service

# systemctl status neutron-openvswitch-agent
# systemctl status neutron-ovs-cleanup.service
  systemctl status neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service
# systemctl status neutron-l3-agent.service
  systemctl status neutron-linuxbridge-agent.service

  systemctl status openstack-cinder-api.service openstack-cinder-scheduler.service
  systemctl status openstack-cinder-volume.service target.service
  systemctl status openstack-glance-api.service openstack-glance-registry.service

  systemctl status openstack-nova-api.service openstack-nova-consoleauth.service
  systemctl status openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
  systemctl status openstack-nova-compute.service

  systemctl status openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
  systemctl status openstack-magnum-api.service openstack-magnum-conductor.service

# ovs-vsctl show
}

function cinder-startup {
  echo start LVM2 and Cinder block storage service ...
  systemctl start lvm2-lvmetad.service
  systemctl status lvm2-lvmetad.service

  systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
  systemctl status openstack-cinder-api.service openstack-cinder-scheduler.service

  systemctl start openstack-cinder-volume.service target.service
  systemctl status openstack-cinder-volume.service target.service

  for i in {1..3} ; do
    echo $i sleeping a bit to allow Cinder Block Storage service time to startup ...
    sleep 1
  done
}

function glance-startup {
  echo start Glance VM image service
  systemctl start openstack-glance-api.service openstack-glance-registry.service
  systemctl status openstack-glance-api.service openstack-glance-registry.service

  for i in {1..3} ; do
    echo $i sleeping a bit to allow Glance VM-image service time to startup ...
    sleep 1
  done
}

function httpd-startup {
  echo start httpd with Keystone and Horizon dashboard webapps and Openstack REST services ...
  systemctl start httpd
  systemctl status httpd

  for i in {1..3} ; do
    echo $i sleeping a bit to allow HTTPD webapp and REST services time to startup ...
    sleep 1
  done
}

function nova-startup {
  echo Nova compute and related services startup ...
  systemctl start openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
  systemctl status openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

  systemctl start libvirtd.service openstack-nova-compute.service
  systemctl status libvirtd.service openstack-nova-compute.service

  for i in {1..3} ; do
    echo $i sleeping a bit to allow Nova compute and related services time to startup ...
    sleep 1
  done
}

function neutron-startup {
  echo Neutron networking services startup ...
  systemctl start neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service
  systemctl status neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service

  systemctl start neutron-linuxbridge-agent.service
  systemctl status neutron-linuxbridge-agent.service

# systemctl start neutron-openvswitch-agent
# systemctl status neutron-openvswitch-agent

# systemctl start neutron-ovs-cleanup.service
# systemctl status neutron-ovs-cleanup.service

# systemctl start neutron-l3-agent.service
# systemctl status neutron-l3-agent.service

  for i in {1..3} ; do
    echo $i sleeping a bit to allow Neutron networking services time to startup ...
    sleep 1
  done
}

function heat-startup {
  echo Heat VM orchestration services startup ...
  systemctl start openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
  systemctl status openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
  for i in {1..3} ; do
    echo $i sleeping a bit to allow Heatr orchestration services time to startup ...
    sleep 1
  done
}

function magnum-startup {
  echo Magnum Container orchestration services startup ...
  systemctl start openstack-magnum-api.service openstack-magnum-conductor.service
  systemctl status openstack-magnum-api.service openstack-magnum-conductor.service
}

function pike-startup {
  echo presumably OVS has been started at boot, but if not:
# ovs-vsctl list-br
# if [ $? != 0 ] ; then
#   systemctl status openvswitch
# fi 
# systemctl status openvswitch.service

  systemctl status neutron-linuxbridge-agent

  echo start mariadb, rabbitmq, and memcached ...
  systemctl start mariadb.service
  systemctl status mariadb.service
  if [ $? != 0 ] ; then
    echo mariadb.service startup failure ... aborting pike sysboot ...
    return
  fi 

  systemctl start rabbitmq-server.service
  systemctl status rabbitmq-server.service

  systemctl start memcached.service
  systemctl status memcached.service

  for i in {1..3} ; do
    echo $i sleeping a bit to allow DB and MQ and MemCache services time to startup ...
    sleep 1
  done 

  glance-startup -v
  cinder-startup -v
  nova-startup -v
  neutron-startup -v
  heat-startup -v
  magnum-startup -v
  httpd-startup -v

  echo Ok ... perform CLI verification of services:
  pike-verify -v
}

function pike-shutdown {
# echo some NICs may be attached to OVS bridges, so DO NOT shutdown openvswtich ...
  systemctl stop openstack-cinder-volume.service target.service
  systemctl status openstack-cinder-volume.service target.service

  systemctl stop openstack-cinder-api.service openstack-cinder-scheduler.service
  systemctl status openstack-cinder-api.service openstack-cinder-scheduler.service

  systemctl stop openstack-magnum-api.service openstack-magnum-conductor.service
  systemctl status openstack-magnum-api.service openstack-magnum-conductor.service

  systemctl stop openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
  systemctl status openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service

#  systemctl stop lvm2-lvmetad.service
#  systemctl status lvm2-lvmetad.service

# systemctl stop neutron-l3-agent.service
# systemctl status neutron-l3-agent.service

# systemctl stop neutron-ovs-cleanup.service
# systemctl status neutron-ovs-cleanup.service

# systemctl stop neutron-openvswitch-agent
# systemctl status neutron-openvswitch-agent

  systemctl stop neutron-linuxbridge-agent.service
  systemctl status neutron-linuxbridge-agent.service

  systemctl stop neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service
  systemctl status neutron-server.service neutron-dhcp-agent.service neutron-metadata-agent.service

  systemctl stop libvirtd.service openstack-nova-compute.service
  systemctl status libvirtd.service openstack-nova-compute.service

  systemctl stop openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
  systemctl status openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

  systemctl stop openstack-glance-api.service openstack-glance-registry.service
  systemctl status openstack-glance-api.service openstack-glance-registry.service

  systemctl stop httpd
  systemctl status httpd

  systemctl stop memcached.service
  systemctl status memcached.service

  systemctl stop rabbitmq-server.service
  systemctl status rabbitmq-server.service

  systemctl stop mariadb.service
  systemctl status mariadb.service
}

if [[ $1 == up ]] ; then pike-startup ; fi
if [[ $1 == down ]] ; then pike-shutdown ; fi

systemctl status openstack-nova-compute.service >& /dev/null
if [ $? == 0 ] ; then
  pike-status -v
else
  echo Pike Openstack services are currently inactive ...
fi

######################################################

scmId=$Id$
