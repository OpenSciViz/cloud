#!/bin/sh

controllerIP=127.0.0.1
#controllerIP=`grep controller /etc/hosts | awk '{print $1}'`
echo controllerIP $controllerIP

file=/etc/pike/heat/heat.conf
orig=/etc/pike/heat/.orig-$(basename $file)
jdate=`date "+%Y_%j_%H_%M"`
orig=${orig}${jdate}
if [ ! -e $orig ] ; then
  cp -p $file $orig
fi

function crudset {
  file=/etc/pike/heat/heat.conf
  section=database
  key=connection
  val='mysql+pymysql://heat:cloud@controller/heat'

  if [ $1 ] ; then file="$1" ; fi
  if [ $2 ] ; then section="$2" ; fi
  if [ $3 ] ; then key="$3" ; fi
  if [ $4 ] ; then val="$4" ; fi

  touch $file
  crudini --set --existing $file $section $key $val
  if [ $? != 0 ] ; then
    crudini --set $file $section $key $val
  fi
  crudini --get $file $section $key
}

function heatset {
  crudset $file database connection 'mysql+pymysql://heat:cloud@controller/heat'

  crudset $file DEFAULT transport_url rabbit://openstack:cloud@controller
  crudset $file DEFAULT auth_strategy keystone
  crudset $file DEFAULT my_ip $controllerIP
  crudset $file DEFAULT enabled_backends lvm
  crudset $file DEFAULT glance_api_servers http://controller:9292
  crudset $file DEFAULT heat_metadata_server_url http://controller:8000
  crudset $file DEFAULT heat_waitcondition_server_url http://controller:8000/v1/waitcondition
  crudset $file DEFAULT stack_domain_admin heat_domain_admin
  crudset $file DEFAULT stack_domain_admin_password HEAT_DOMAIN_PASS
  crudset $file DEFAULT stack_user_domain_name heat

  crudset $file keystone_authtoken auth_uri http://controller:5000
  crudset $file keystone_authtoken auth_url http://controller:35357
  crudset $file keystone_authtoken memcached_servers controller:11211
  crudset $file keystone_authtoken auth_type password
  crudset $file keystone_authtoken project_domain_name default
  crudset $file keystone_authtoken user_domain_name default
  crudset $file keystone_authtoken project_name service
  crudset $file keystone_authtoken username heat
  crudset $file keystone_authtoken password cloud

  crudset $file clients_keystone auth_uri http://controller:35357
  crudset $file ec2authtoken auth_uri http://controller:5000

  crudset $file trustee auth_type password
  crudset $file trustee auth_url http://controller:35357
  crudset $file trustee username heat
  crudset $file trustee password cloud
  crudset $file trustee user_domain_name default

  crudset $file lvm volume_driver heat.volume.drivers.lvm.LVMVolumeDriver
  crudset $file lvm volume_group heat-volumes
  crudset $file lvm iscsi_protocol iscsi
  crudset $file lvm iscsi_helper lioadm

  crudset $file oslo_concurrency lock_path /var/lib/heat/tmp
}

function heat-dbini {
  su -s /bin/sh -c 'heat-manage db_sync' heat
}

function heat-test {
  openstack volume create --size 1 volume1
  openstack volume list
# openstack server add volume instance-name volume1
}

funtion heat-stack {
# https://docs.openstack.org/heat/pike/install/launch-instance.html
  export NET_ID=$(openstack network list | awk '/ provider / { print $2 }')

  openstack stack create -t demo-template.yml --parameter "NetID=$NET_ID" stack
  openstack stack list
  openstack stack output show --all stack
  openstack server list
}

echo diff $orig $file
# diff $orig $file

echo heat whatcloud instructions seem congruent with openstack.org manual install guide: 
echo avoid password-prompt and instead set it directly ... see funcs in authsetup.sh
echo pike release added a few more crudsets ...

heatset -v 

echo if the heatset crudini worked, perform the db setup ...
echo su -s /bin/sh -c \"heat-manage db sync\" heat

echo systemctl start openstack-heat-api.service openstack-heat-scheduler.service

