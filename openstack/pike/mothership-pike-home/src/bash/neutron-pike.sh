#!/bin/sh

file=/etc/pike/neutron/neutron.conf
orig=/etc/pike/neutron/.orig-$(basename $file)
jdate=`date "+%Y_%j_%H_%M"`
orig=${orig}${jdate}
if [ ! -e $orig ] ; then
  cp -p $file $orig
fi

ml2file=/etc/pike/neutron/plugins/ml2/ml2_conf.ini
origml2=/etc/pike/neutron/plugins/ml2/.orig-$(basename $ml2file)
jdate=`date "+%Y_%j_%H_%M"`
origml2=${orig}${jdate}
if [ ! -e $origml2 ] ; then
  cp -p $ml2file $origml2
fi

lbrdgfile=/etc/pike/neutron/plugins/ml2/linuxbridge_agent.ini
origlbrdg=/etc/pike/neutron/plugins/.orig-$(basename $lbrdgfile)
jdate=`date "+%Y_%j_%H_%M"`
origovs=${orig}${jdate}
if [ ! -e $origovs ] ; then
  cp -p $lbrdgfile $origlbrdg 
fi

ovsfile=/etc/pike/neutron/plugins/ml2/openvswitch_agent.ini
origovs=/etc/pike/neutron/plugins/.orig-$(basename $ovsfile)
jdate=`date "+%Y_%j_%H_%M"`
origovs=${orig}${jdate}
if [ ! -e $origovs ] ; then
  cp -p $ovsfile $origovs
fi

l3file=/etc/pike/neutron/l3_agent.ini
origl3=/etc/pike/neutron/.orig-$(basename $l3file)
jdate=`date "+%Y_%j_%H_%M"`
origl3=${orig}${jdate}
if [ ! -e $origl3 ] ; then
  cp -p $l3file $origl3
fi

dhcpfile=/etc/pike/neutron/dhcp_agent.ini
origdhcp=/etc/pike/neutron/.orig-$(basename $dhcpfile)
jdate=`date "+%Y_%j_%H_%M"`
origdhcp=${orig}${jdate}
if [ ! -e $origdhcp ] ; then
  cp -p $dhcpfile $origdhcp
fi

metafile=/etc/pike/neutron/metadata_agent.ini
origmeta=/etc/pike/neutron/.orig-$(basename $metafile)
jdate=`date "+%Y_%j_%H_%M"`
origmeta=${orig}${jdate}
if [ ! -e $origmeta ] ; then
  cp -p $metafile $origmeta
fi

function crudset {
  file=/etc/pike/neutron/neutron.conf
  section=database
  key=connection
  val='mysql+pymysql://neutron:cloud@controller/neutron'

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
  file=/etc/pike/neutron/neutron.conf

  echo set neutron controller conf
  echo DEFAULT
  crudset $file DEFAULT core_plugin ml2  
  echo pike openstack.org install indicates all other plugions should be disabled by setting it empty for provider newtorks
  echo keep it simple and just setup a provider network ... controller:
  echo using \"\" results in unexpected behavior
  crudset $file DEFAULT service_plugins \"\"
  echo pike openstack.org install indicates all service plugin should be set to router for self-service networks
  echo this is also set in whatcloud conf
# crudset $file DEFAULT service_plugins router
# crudset $file DEFAULT allow_overlapping_ips true

  crudset $file DEFAULT notify_nova_on_port_status_changes true
  crudset $file DEFAULT notify_nova_on_port_data_changes true

  crudset $file DEFAULT transport_url rabbit://openstack:cloud@controller
  crudset $file DEFAULT auth_strategy keystone

  echo Pike install does not mention firewall_driver in neutron.conf ... see linuxbridge_agent.ini securitygroup below ...
# crudset $file DEFAULT firewall_driver neutron.virt.firewall.NoopFirewallDriver
# Optional parameter - if you want to thin provision VM disks
# crudset $file DEFAULT disk_allocation_ratio 4.0

  echo database
  crudset $file database connection 'mysql+pymysql://neutron:cloud@controller/neutron'

  echo keystone_authtoken
  crudset $file keystone_authtoken auth_uri 'http://controller:5000'
  crudset $file keystone_authtoken auth_url 'http://controller:35357'
  crudset $file keystone_authtoken memcached_servers 'controller:11211'
  crudset $file keystone_authtoken auth_type password
  crudset $file keystone_authtoken project_domain_name default
  crudset $file keystone_authtoken user_domain_name default
  crudset $file keystone_authtoken project_name service
  crudset $file keystone_authtoken username neutron
  crudset $file keystone_authtoken password cloud

  echo nova ... Tell neutron how to talk to nova to inform nova about changes in the network
  crudset $file nova auth_url http://controller:35357
  crudset $file nova auth_type password
  crudset $file nova project_domain_name default
  crudset $file nova user_domain_name default
  crudset $file nova region_name RegionOne
  crudset $file nova project_name service
  crudset $file nova username nova
  crudset $file nova password cloud

  # this is not indicated in the Newton whatcloud blog, but is for Pike:
  crudset $file oslo_concurrency lock_path /var/lib/neutron/tmp

  echo ml2 file $ml2file 
  echo according to Pike ... Warning: After you configure the ML2 plug-in, removing values in the type_drivers option can lead to database inconsistency.
  echo whatcloud ... In our environment we will use vlan networks ... could also use vxlan and gre
  echo Pike ... includes vxlan type for self-service networks
  crudset $ml2file ml2 type_drivers 'flat,vlan'
# crudset $ml2file ml2 type_drivers 'flat,vlan,vxlan'

  echo whatcloud ... tell neutron that all our customer networks will be based on vlans
  crudset $ml2file ml2 tenant_network_types vlan
  echo Pike ... set tenant_network_types to "" disables self-service networks.
  echo Pike ... set tenant_network_types to 'vxlan' for self-service networks.
  crudset $ml2file ml2 tenant_network_types \"\"
# crudset $ml2file ml2 tenant_network_types vxlan

# echo SDN type is OpenVSwitch
# crudset $ml2file ml2 mechanism_drivers 'openvswitch,l2population'
  echo follow the install guide and use linux bridge
  echo https://docs.openstack.org/neutron/pike/install/controller-install-option1-rdo.html
  crudset $ml2file ml2 mechanism_drivers linuxbridge
  echo enable port security driver
  crudset $ml2file ml2 extension_drivers port_security

# echo whatcloud ... External network is a flat network
# crudset $ml2file ml2_type_flat flat_networks external
  echo Pike provider as flat virtual network ... sets ml2_type_flat to provider
  crudset $ml2file ml2_type_flat flat_networks provider
 
# echo the range we want to use for vlans assigned to customer networks.
# crudset $ml2file ml2_type_vlan network_vlan_ranges 'external,vlan:989:999'

# echo Pike ... set vxlan for provider network?
# crudset $ml2file ml2_type_vxlan network_vlan_ranges '1:999'
  
# echo Use Ip tables based firewall
# crudset $ml2file securitygroup firewall_driver iptables_hybrid  
  echo Pike uses ipset
  crudset $ml2file securitygroup enable_ipset true  

  echo Pike install uses linux bridge agent
  echo ini file $lbrdgfile
  crudset $lbrdgfile linux_bridge physical_interface_mappings 'provider:eth0' 
  crudset $lbrdgfile vxlan enable_vxlan false 
  crudset $lbrdgfile securitygroup enable_security_group true
  crudset $lbrdgfile securitygroup firewall_driver 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver'

# echo whatcloud uses OVS bridge agent
# echo now editing file $ovsfile 
# echo whatcloud: Note that we are mapping alias\(es\) to the bridges. Later we will use these aliases \(vlan,external\) to define networks inside OS.
# echo Configure the section for OpenVSwitch
# crudset $ovsfile ovs bridge_mappings 'vlan:br-vlan,external:br-ex'
# crudset $ovsfile agent l2_population true

# echo whatcloud/ocata ... indicates this
# crudset $ovsfile securitygroup enable_security_group = true
# crudset $ovsfile securitygroup firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
# echo whatcloud indicates a single item for securitygroup
# crudset $ovsfile securitygroup firewall_driver iptables_hybrid
# echo Pike ... also ipset efficiency in security group rule
# crudset $ovsfile securitygroup enable_ipset true

  echo Pike install ... presumably l3_agent is needed for self-service newtorks, but not provider
# echo l3_agent ... whatcloud ... Tell the agent to use the OVS driver
# crudset $l3file DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
# echo This is required to be set like this by the official documentation.
# echo If you don’t set it to empty as show below, sometimes your router ports in OS will not become Active
# crudset $l3file DEFAULT external_network_bridge \"\"

# echo dhcp_agent ... tell the dhcp_agent to use the OVS driver
# crudset $dhcpfile DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  echo tell the dhcp_agent to use the linuxbridge
  crudset $dhcpfile DEFAULT interface_driver linuxbridge
  crudset $dhcpfile DEFAULT enable_isolated_metadata true
# echo Pike ... does not mention dnsmasq
# crudset $dhscpfile DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq

  echo metadata_agent seems missing in the Pike install ... but maybe it is needed ...
  crudset $metafile DEFAULT nova_metadata_ip controller
  crudset $metafile DEFAULT metadata_proxy_shared_secret cloud

  echo Pike ... sets this symlink:
  ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
}


function neutron-dbini {
  su -s /bin/sh -c "neutron-db-manage --config-file /etc/pike/neutron/neutron.conf --config-file /etc/pike/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
}

function neutron-ovs {
  ovs-vsctl add-br br-ex
  ovs-vsctl add-port br-ex eth1
# ip address add 172.16.0.1/12 dev br-ex

  ovs-vsctl add-br br-vlan
  ovs-vsctl add-port br-vlan eth2

# ip address add 172.17.0.1/12 dev br-int
}

function create-network {
  echo whatcloud indicates DHCP, but try the Pike example here ...
  echo Pike ... must create provider \(external \?\) network before self-service
  echo use name 'external' ala whatcloud, aka the Pike 'provider'
  openstack network create --share --external --provider-physical-network external --provider-network-type flat external
  openstack subnet create --network external --allocation-pool start=172.17.0.100,end=172.17.0.250  --dns-nameserver 8.8.8.8 --gateway 172.17.0.1 --subnet-range 172.17.0.0/12 external

  openstack network create selfservice
  openstack subnet create --network selfservice --dns-nameserver 8.8.4.4 --gateway 172.17.1.1 --subnet-range 172.17.1.0/12 selfservice

  openstack router create router
  neutron router-interface-add router selfservice
  neutron router-gateway-set router external

  ip netns
  neutron router-port-list router
}

echo diff $orig $file
#diff $orig $file

echo diff $origml2 $ml2file

#diff $origml2 $ml2file

echo diff $origovs $ovsfile

#diff $origovs $ovsfile

echo diff $origl3 $l3file
#diff $origl3 $l3file

echo diff $origmeta $metafile
3diff $origmeta $metafile

echo diff $origdhcp $dhcpfile
#diff $origdhcp $dhcpfile

echo systemctl restart openstack-nova-api.service
echo systemctl start neutron-server.service neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
echo systemctl start neutron-l3-agent.service

# openstack extension list --network
# openstack network agent list

