#!/bin/sh

controllerIP=`grep controller /etc/hosts | awk '{print $1}'`
#controllerIP=192.168.122.75
controllerIP=127.0.0.1
echo controllerIP $controllerIP

file=/etc/pike/cinder/cinder.conf
orig=/etc/pike/cinder/.orig-$(basename $file)
jdate=`date "+%Y_%j_%H_%M"`
orig=${orig}${jdate}
if [ ! -e $orig ] ; then
  cp -p $file $orig
fi

function crudset {
  file=/etc/pike/cinder/cinder.conf
  section=database
  key=connection
  val='mysql+pymysql://cinder:cloud@controller/cinder'

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

function cinderset {
  crudset $file database connection 'mysql+pymysql://cinder:cloud@controller/cinder'

  crudset $file DEFAULT transport_url rabbit://openstack:cloud@controller
  crudset $file DEFAULT auth_strategy keystone
  crudset $file DEFAULT my_ip $controllerIP
  crudset $file DEFAULT enabled_backends lvm
  crudset $file DEFAULT glance_api_servers http://controller:9292

  crudset $file keystone_authtoken auth_uri http://controller:5000
  crudset $file keystone_authtoken auth_url http://controller:35357
  crudset $file keystone_authtoken memcached_servers controller:11211
  crudset $file keystone_authtoken auth_type password
  crudset $file keystone_authtoken project_domain_name default
  crudset $file keystone_authtoken user_domain_name default
  crudset $file keystone_authtoken project_name service
  crudset $file keystone_authtoken username cinder
  crudset $file keystone_authtoken password cloud

  crudset $file lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
  crudset $file lvm volume_group cinder-volumes
  crudset $file lvm iscsi_protocol iscsi
  crudset $file lvm iscsi_helper lioadm

  crudset $file oslo_concurrency lock_path /var/lib/cinder/tmp
}

function cinder_test {
  openstack volume create --size 1 volume1
  openstack volume list
# openstack server add volume instance-name volume1
}


echo diff $orig $file
diff $orig $file

echo cinder whatcloud instructions seem congruent with openstack.org manual install guide: 
echo avoid password-prompt and instead set it directly ... see funcs in authsetup.sh

echo su -s /bin/sh -c \'cinder-manage db sync\' cinder


echo systemctl start lvm2-lvmetad.service

echo pvcreate /dev/vdb
echo vgcreate cinder-volumes /dev/vdb

echo systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service

