#!/bin/sh

apifile=/etc/pike/glance/glance-api.conf
orig=/etc/pike/glance/.orig-$(basename $apifile)
jdate=`date "+%Y_%j_%H_%M"`
orig=${orig}${jdate}
if [ ! -e $orig ] ; then
  cp -p $apifile $orig
fi

regfile=/etc/pike/glance/glance-registry.conf
orig=/etc/pike/glance/.orig-$(basename $regfile)
jdate=`date "+%Y_%j_%H_%M"`
orig=${orig}${jdate}
if [ ! -e $orig ] ; then
  cp -p $regfile $orig
fi

function crudset {
  file=/etc/pike/glance/glance-api.conf
  section=database
  key=connection
  val='mysql+pymysql://glance:cloud@controller/glance'

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

crudset $apifile database connection 'mysql+pymysql://glance:cloud@controller/glance'
crudset $regfile database connection 'mysql+pymysql://glance:cloud@controller/glance'

crudset $apifile glance_store stores file,http
crudset $apifile glance_store default_store file
crudset $apifile glance_store filesystem_store_datadir /var/lib/glance/images/

crudset $apifile keystone_authtoken auth_uri http://controller:5000
crudset $apifile keystone_authtoken auth_url http://controller:35357
crudset $apifile keystone_authtoken memcached_servers controller:11211
crudset $apifile keystone_authtoken auth_type password
crudset $apifile keystone_authtoken project_domain_name default
crudset $apifile keystone_authtoken user_domain_name default
crudset $apifile keystone_authtoken project_name service
crudset $apifile keystone_authtoken username glance
crudset $apifile keystone_authtoken password cloud
crudset $apifile paste_deploy flavor keystone

crudset $regfile keystone_authtoken auth_uri http://controller:5000
crudset $regfile keystone_authtoken auth_url http://controller:35357
crudset $regfile keystone_authtoken memcached_servers controller:11211
crudset $regfile keystone_authtoken auth_type password
crudset $regfile keystone_authtoken project_domain_name default
crudset $regfile keystone_authtoken user_domain_name default
crudset $regfile keystone_authtoken project_name service
crudset $regfile keystone_authtoken username glance
crudset $regfile keystone_authtoken password cloud
crudset $regfile paste_deploy flavor keystone

echo diff $orig $file
diff $orig $file

echo glance whatcloud instructions seem congruent with openstack.org manual install guide: 
echo avoid password-prompt and instead set it directly ... see funcs in authsetup.sh

echo su -s /bin/sh -c \"glance-manage db_sync\" glance

echo systemctl start openstack-glance-api.service openstack-glance-registry.service
