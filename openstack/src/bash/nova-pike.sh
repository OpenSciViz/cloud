#!/bin/sh

file=/etc/pike/nova/nova.conf
orig=/etc/pike/nova/.orig-$(basename $file)
jdate=`date "+%Y_%j_%H_%M"`
orig=${orig}${jdate}
if [ ! -e $orig ] ; then
  cp -p $file $orig
fi

function crudset {
  file=/etc/pike/nova/nova.conf
  section=database
  key=connection
  val='mysql+pymysql://nova:cloud@controller/nova'

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

function setconf {
  echo fetch my_ip from /etc/hosts controller entry
# controlIP=`grep controller /etc/hosts|awk '{print $1}'`
  controlIP=127.0.0.1 
  echo my_ip shall be set to $controlIP

  echo whatcloud places \[libvirt\] in nova-compute.conf, but Ocata places it in nova.conf
  echo this is important for nested virtualization ... change qemu back to kvm for baremetal:
  crudset $file libvirt virt_type qemu

  echo yet the pike install mentions: 
  egrep -c '(vmx|svm)' /proc/cpuinfo
  echo If this command returns a value of one or greater, your compute node supports hardware acceleration which typically requires no additional configuration.
# crudset $file libvirt virt_type kvm
 
  echo try to enable virsh console access ... although this bool may only pertain to the websocket noVNC console ...
  crudset $file serial_console enabled true
 
  echo set nova controller conf .. compute-node conf follows ...
  echo DEFAULT
  crudset $file DEFAULT enabled_apis 'osapi_compute,metadata'
  crudset $file DEFAULT transport_url rabbit://openstack:cloud@controller
  crudset $file DEFAULT auth_strategy keystone
  crudset $file DEFAULT my_ip $controlIP
  crudset $file DEFAULT use_neutron True
  crudset $file DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
# Optional parameter - if you want to thin provision VM disks
  crudset $file DEFAULT disk_allocation_ratio 4.0

  echo databases
  crudset $file api_database connection 'mysql+pymysql://nova:cloud@controller/nova_api'
  crudset $file database connection 'mysql+pymysql://nova:cloud@controller/nova'

  echo keystone_authtoken ... note memcache endpoint is NOT http
  crudset $file keystone_authtoken memcached_servers 'controller:11211'
  crudset $file keystone_authtoken auth_uri 'http://controller:5000'
  crudset $file keystone_authtoken auth_url 'http://controller:35357'
  crudset $file keystone_authtoken auth_type password
  crudset $file keystone_authtoken project_domain_name default
  crudset $file keystone_authtoken user_domain_name default
  crudset $file keystone_authtoken project_name service
  crudset $file keystone_authtoken username nova
  crudset $file keystone_authtoken password cloud

  echo vnc
  crudset $file vnc enabled true
# crudset $file vnc vncserver_listen 0.0.0.0
  crudset $file vnc vncserver_listen '$my_ip'
  crudset $file vnc vncserver_proxyclient_address '$my_ip'

  echo glance
# Nova needs to talk to glance to get the images
  crudset $file glance api_servers 'http://controller:9292'

  echo oslo
# Some locking mechanism for message queing (Just use it.)
  crudset $file oslo_concurrency lock_path /var/lib/nova/tmp

  echo placement
# not in whatcloud
  crudset $file placement os_region_name RegionOne
  crudset $file placement project_domain_name default
  crudset $file placement project_name service
  crudset $file placement auth_type password
  crudset $file placement user_domain_name default
  crudset $file placement auth_url 'http://controller:35357/v3'
  crudset $file placement username placement
  crudset $file placement password cloud

  echo scheduler
  crudset $file scheduler discover_hosts_in_cells_interval 300

# this is described later in the neutron section
  echo tell nova to use neutron ... for compute and controller:
  crudset $file neutron url 'http://controller:9696'
  crudset $file neutron auth_url 'http://controller:35357'
  crudset $file neutron auth_type password
  crudset $file neutron project_domain_name default
  crudset $file neutron user_domain_name default
  crudset $file neutron region_name RegionOne
  crudset $file neutron project_name service
  crudset $file neutron username neutron
  crudset $file neutron password cloud
# this is not in whatcloud ... for neutron-controller:
  crudset $file neutron service_metadata_proxy true
  crudset $file neutron metadata_proxy_shared_secret cloud

  echo tell nova about cinder block storage
  crudset $file cinder os_region_name RegionOne
}

# this may o longer be needed in Pike
function httpd-fix {
  echo httpd complains if any xml ge or lt items are placed into a single line ...
  nova_http='

<!-- openstack.org Ocata install: Due to a packaging bug ... enable access to the Placement API ... -->
<Directory /usr/bin>
  <IfVersion >= 2.4>
    Require all granted
  </IfVersion>
  <IfVersion < 2.4>
    Order allow,deny
    Allow from all
  </IfVersion>
</Directory>

'
  echo $nova_http >> /etc/pike/httpd/conf.d/00-nova-placement-api.conf
}

function nova-dbini {
  su -s /bin/sh -c 'nova-manage api_db sync' nova
  su -s /bin/sh -c 'nova-manage db sync' nova

  # whatcloud Newton does not mention these -- perhaps new in Ocata and Pike and beyond
  su -s /bin/sh -c 'nova-manage cell_v2 map_cell0' nova
  su -s /bin/sh -c 'nova-manage cell_v2 create_cell --name=cell1 --verbose' nova
}

echo diff $orig $file
# diff $orig $file

# setconf
# nova-dbini

echo nova-manage cell_v2 list_cells

echo systemctl restart httpd
echo systemctl start openstack-nova-api openstack-nova-consoleauth openstack-nova-scheduler openstack-nova-conductor openstack-nova-novncproxy
echo systemctl start libvirtd openstack-nova-compute

echo systemctl start openstack-nova-api openstack-nova-consoleauth openstack-nova-scheduler openstack-nova-conductor openstack-nova-novncproxy

echo openstack hypervisor list
echo openstack catalog list

echo nova-status upgrade check
echo openstack image list

echo su -s /bin/sh -c 'nova-manage cell_v2 discover_hosts --verbose' nova

echo nova-status upgrade check

