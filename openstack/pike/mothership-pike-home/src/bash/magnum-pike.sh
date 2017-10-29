#!/bin/sh

controllerIP=127.0.0.1
#controllerIP=`grep controller /etc/hosts | awk '{print $1}'`
echo controllerIP $controllerIP

file=/etc/pike/magnum/magnum.conf
orig=/etc/pike/magnum/.orig-$(basename $file)
jdate=`date "+%Y_%j_%H_%M"`
orig=${orig}${jdate}
if [ ! -e $orig ] ; then
  cp -p $file $orig
fi

function crudset {
  file=/etc/pike/magnum/magnum.conf
  section=database
  key=connection
  val='mysql+pymysql://magnum:cloud@controller/magnum'

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

function magnumset {
  crudset $file api host $controllerIP

# crudset $file certificates cert_manager_type barbican
  crudset $file certificates cert_manager_type x509keypair

  crudset $file cinder_client region_name RegionOne

  crudset $file database connection 'mysql+pymysql://magnum:cloud@controller/magnum'

  crudset $file DEFAULT transport_url rabbit://openstack:cloud@controller

  crudset $file keystone_authtoken memcached_servers controller:11211
  crudset $file keystone_authtoken auth_version v3
  crudset $file keystone_authtoken auth_uri http://controller:5000/v3
  crudset $file keystone_authtoken project_domain_id default
  crudset $file keystone_authtoken project_name service
  crudset $file keystone_authtoken user_domain_id default
  crudset $file keystone_authtoken password cloud
  crudset $file keystone_authtoken username magnum
  crudset $file keystone_authtoken auth_url http://controller:35357
  crudset $file keystone_authtoken auth_type password

  crudset $file trust trustee_domain_name magnum
  crudset $file trust trustee_domain_admin_name magnum_domain_admin
  crudset $file trust trustee_domain_admin_password cloud
  crudset $file trust trustee_keystone_interface public

  crudset $file oslo_messaging_notifications driver messaging

  crudset $file oslo_concurrency lock_path /var/lib/magnum/tmp
}

function magnum-dbini {
  su -s /bin/sh -c 'magnum-db-manage upgrade' magnum
}

function magnum-test {
  openstack volume create --size 1 volume1
  openstack volume list
# openstack server add volume instance-name volume1
}

function magnum-stack {
# https://docs.openstack.org/magnum/pike/install/launch-instance.html
  export NET_ID=$(openstack network list | awk '/ provider / { print $2 }')

  openstack stack create -t demo-template.yml --parameter "NetID=$NET_ID" stack
  openstack stack list
  openstack stack output show --all stack
  openstack server list
}

echo diff $orig $file
# diff $orig $file

echo magnum whatcloud instructions seem congruent with openstack.org manual install guide: 
echo avoid password-prompt and instead set it directly ... see funcs in authsetup.sh
echo pike release added a few more crudsets ...

echo magnumset -v 

echo if the magnumset crudini worked, perform the db setup ...
echo su -s /bin/sh -c \"magnum-db-manage upgrade\" magnum

echo systemctl start openstack-magnum-api.service openstack-magnum-conductor.service

