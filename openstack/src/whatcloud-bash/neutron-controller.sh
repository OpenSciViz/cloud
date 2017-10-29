#!/bin/sh
echo neutron-controller

openstack user create --domain default --password-prompt neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

echo Neutron Self Sevice Newtorking

echo Edit the /etc/neutron/neutron.conf file and complete the following actions:
cp -p /etc/neutron/neutron.conf /etc/neutron/.neutron.conf

echo In the [database] section, configure database access:
openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:cloud@controller/neutron

echo Comment out or remove any other connection options in the [database] section.

echo In the [DEFAULT] section, enable the Modular Layer 2 (ML2) plug-in, router service, and overlapping IP addresses:

openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true

echo In the [DEFAULT] section, configure RabbitMQ message queue access:
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:cloud@controller

echo In the [DEFAULT] and [keystone_authtoken] sections, configure Identity service access:
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password cloud

echo Comment out or remove any other options in the [keystone_authtoken] section.

echo In the [DEFAULT] and [nova] sections, configure Networking to notify Compute of network topology changes:

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

openstack-config --set /etc/neutron/neutron.conf nova auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf nova auth_type password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password cloud

echo In the [oslo_concurrency] section, configure the lock path:

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

###

echo Refs.
echo https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/4/html/Installation_and_Configuration_Guide/chap-Installing_the_OpenStack_Networking_Service.html
echo above ref. indicates ml2 type_drivers "local,flat,vlan,vxlan" and ml2 "mechanism_drivers openvswitch,linuxbridge,l2population"
echo https://docs.openstack.org//ocata/install-guide-rdo/neutron-controller-install-option2.html
echo above ref does not mention "local" of "openvswitch"

echo Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file and complete the following actions:

echo In the [ml2] section, enable flat, VLAN, and VXLAN networks ... and local?

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers local,flat,vlan,vxlan

echo In the [ml2] section, enable VXLAN self-service networks:

#openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types local
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types flat
#openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan

echo In the [ml2] section, enable the Linux bridge and layer-2 population mechanisms:

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,linuxbridge,l2population

echo After you configure the ML2 plug-in, removing values in the type_drivers option can lead to database inconsistency.

echo The Linux bridge agent only supports VXLAN overlay networks.

echo In the [ml2] section, enable the port security extension driver:

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security

echo In the [ml2_type_flat] section, configure the provider virtual network as a flat network:

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider

echo In the [ml2_type_vxlan] section, configure the VXLAN network identifier range for self-service networks:

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

echo In the [securitygroup] section, enable ipset to increase efficiency of security group rules:

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true

###

echo Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini file and complete the following actions:

echo physical_interface_mappings PROVIDER_INTERFACE_NAME is the name of the underlying provider physical network interface.
echo See Host networking for more information.

echo In the [linux_bridge] section, map the provider virtual network to the provider physical network interface:
echo does this inform neutron to create a linux bridge and enslave eth1 to it?

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth1

echo In the [vxlan] section, enable VXLAN overlay networks, configure the IP address of the physical network interface that 
echo handles overlay networks, and enable layer-2 population:

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip 172.17.2.1
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true

echo local_ip OVERLAY_INTERFACE_IP_ADDRESS is the IP address of the underlying physical network interface that handles overlay networks.
echo The example architecture uses the management interface to tunnel traffic to the other nodes.
echo Therefore the local_ip OVERLAY_INTERFACE_IP_ADDRESS is the management IP address of the controller node. See Host networking for more information.

echo In the [securitygroup] section, enable security groups and configure the Linux bridge iptables firewall driver:

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true

echo according to https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/11/html/manual_installation_procedures/sect-configure_the_networking_service

echo Redhat indicates EITHER:
# openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
echo OR:
# openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
###

echo Edit the /etc/neutron/l3_agent.ini file and complete the following actions:

echo In the [DEFAULT] section, configure the Linux bridge interface driver and external network bridge:

openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge

###

echo Edit the /etc/neutron/dhcp_agent.ini file and complete the following actions:

echo In the [DEFAULT] section, configure the Linux bridge interface driver, Dnsmasq DHCP driver, and enable isolated metadata so instances on provider networks can access metadata over the network:

openstack-config --set  /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
openstack-config --set  /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set  /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

###

echo Edit the /etc/neutron/metadata_agent.ini file and complete the following actions:

echo In the [DEFAULT] section, configure the metadata host and shared secret:
echo set METADATA_SECRET with a suitable secret for the metadata proxy.

openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret cloud

echo Edit the /etc/nova/nova.conf file and perform the following actions:

echo In the [neutron] section, configure access parameters, enable the metadata proxy, and configure the secret:

openstack-config --set /etc/nova/nova.conf neutron url http://controller:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password cloud
openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy true
openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret cloud

###

# from https://docs.openstack.org/ocata/networking-guide/config-ovsfwdriver.html

echo On nodes running the Open vSwitch agent, edit the openvswitch_agent.ini file and enable the firewall driver.

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver openvswitch

###

echo according to Redhat thses settings must be self-consitent -- all true or all false:

echo https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/11/html/manual_installation_procedures/sect-configure_the_networking_service

openstack-config --set /etc/nova/nova.conf DEFAULT vif_plugging_is_fatal False
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes False
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes False

echo The Networking service initialization scripts expect a symbolic link /etc/neutron/plugin.ini pointing 
echo to the ML2 plug-in configuration file, /etc/neutron/plugins/ml2/ml2_conf.ini. 
echo If this symbolic link does not exist, create it using the following command:

echo ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

echo Populate the database:

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

echo Database population occurs later for Networking because the script requires complete server and plug-in configuration files.
echo Restart the Compute API service:

systemctl restart openstack-nova-api.service

echo Start the Networking services and configure them to start when the system boots.

For both networking options:

systemctl status neutron-server.service neutron-linuxbridge-agent.service neutron-openvswitch-agent neutron-dhcp-agent.service neutron-metadata-agent.service
# systemctl start neutron-server.service neutron-linuxbridge-agent.service neutron-openvswitch-agent neutron-dhcp-agent.service  neutron-metadata-agent.service

echo For networking option 2, also enable and start the layer-3 service:

systemctl status neutron-l3-agent.service
# systemctl start neutron-l3-agent.service

######################################################

scmId=$Id$
