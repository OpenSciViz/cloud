#!/bin/sh
# https://docs.openstack.org/python-openstackclient/latest/cli/command-objects/user.html

invoke=$_
string="$0"

subshell=${string//[-._]/}
# echo "subshell == $subshell"

if [ "$subshell" != "bash" ]; then
  echo "$invoke" must be sourced
  echo try: \"'. '${invoke}\" ... or: \"source ${invoke}\"
  exit
fi

#source admin-openrc

export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=oct2017cloud
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

function pwdchange {
  usr=admin
  if [ $1 ] ; then usr="$1" ; fi

  oldpwd=cloud
  if [ $2 ] ; then oldpwd="$2" ; fi

  newpwd=oct2017cloud
  if [ $3 ] ; then newpwd="$3" ; fi

  echo openstack user password set --original-password $oldpwd --password $newpwd $usr
  openstack user password set --original-password $oldpwd --password $newpwd
} 

function keystone-auth {
  echo ================================== start keystone ======================================
  echo create service and demo projects ... quotes escape may not work in this func, so do this part once manually ...
  echo whatcloud indicates just this:
  echo openstack project create --domain default --description 'Service Project' service
# time openstack project create --domain default --description 'Service Project' service

  echo openstack.org install supplements above with:
  echo openstack project create --domain default --description 'Demo Project' demo
# time openstack project create --domain default --description 'Demo Project' demo

  echo supplement above with hon project:
  echo openstack project create --domain default --description 'Hon Project' hon
# time openstack project create --domain default --description 'Hon Project' hon

  echo above is performed just once  ... \"Do not repeat this step when creating additional users for this project.\"

  time openstack role create user 
  time openstack user create --domain default --password cloud demo
  time openstack role add --project demo --user demo user

  time openstack user create --domain default --password cloud hon
  time openstack role add --project demo --user hon user

  time openstack --os-auth-url http://controller:35357/v3 --os-project-domain-name default --os-user-domain-name default --os-project-name admin --os-username admin token issue
  time openstack --os-auth-url http://controller:5000/v3 --os-project-domain-name default --os-user-domain-name default --os-project-name demo --os-username demo token issue
  time openstack --os-auth-url http://controller:5000/v3 --os-project-domain-name default --os-user-domain-name default --os-project-name hon --os-username hon token issue

  time openstack token issue
  echo ================================== done keystone ======================================
}

function glance-auth {
  echo ================================== start glance ======================================
  echo glance whatcloud instructions seem congruent with openstack.org manual install guide: 
  echo avoid password-prompt and instead set it directly
  openstack user create --domain default --password cloud glance
  openstack role add --project service --user glance admin
  openstack service create --name glance --description 'OpenStack Image' image
  openstack endpoint create --region RegionOne image public http://controller:9292
  openstack endpoint create --region RegionOne image internal http://controller:9292
  openstack endpoint create --region RegionOne image admin http://controller:9292
  echo ================================== done glance ======================================
}

function nova-auth {
  echo ================================== start nova ======================================
  echo the whatcloud blog \(Newton\) config shows fewer items than openstack.org \(Ocata\) ...
  echo Create the user and assign the roles
  openstack user create --domain default --password cloud nova
  openstack role add --project service --user nova admin
  echo Create the service and the corresponding endpoints
  openstack service create --name nova --description 'OpenStack Compute' compute
  echo tenent_ids are not mentioned in openstack.org
  openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1    #/%\(tenant_id\)s
  openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1  #/%\(tenant_id\)s
  openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1     #/%\(tenant_id\)s 
  echo placement items are not mentioned in whatcloud
  openstack user create --domain default --password cloud placement
  openstack role add --project service --user placement admin
  openstack service create --name placement --description 'Placement API' placement
  openstack endpoint create --region RegionOne placement public http://controller:8778
  openstack endpoint create --region RegionOne placement internal http://controller:8778
  openstack endpoint create --region RegionOne placement admin http://controller:8778
  echo ================================== done nova ======================================
}

function neutron-auth {
  echo ================================== start neutron  ======================================
  openstack user create --domain default --password cloud neutron
  openstack role add --project service --user neutron admin
  echo Create the neutron service and the respective endpoints
  openstack service create --name neutron --description 'OpenStack Networking' network
  openstack endpoint create --region RegionOne network public 'http://controller:9696'
  openstack endpoint create --region RegionOne network internal 'http://controller:9696'
  openstack endpoint create --region RegionOne network admin 'http://controller:9696'
  echo ================================== done neutron  ======================================
}

function cinder-auth {
  echo ================================== start cinder  ======================================
  openstack user create --domain default --password cloud cinder
  openstack role add --project service --user cinder admin
  openstack service create --name cinderv2 --description 'OpenStack Block Storage v2' volumev2
  openstack service create --name cinderv3 --description 'OpenStack Block Storage v3' volumev3
  openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s
  openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s
  openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s
  openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
  openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
  openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s
  echo ================================== done cinder  ======================================
}

function heat-auth {
  echo ================================== start heat  ======================================
  openstack user create --domain default --password cloud heat
  openstack role add --project service --user heat admin
  openstack service create --name heat --description 'Heat Orchestration' orchestration
  openstack service create --name heat-cfn --description 'Heat Orchestration' cloudformation
  openstack endpoint create --region RegionOne orchestration public http://controller:8004/v1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne orchestration internal http://controller:8004/v1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne orchestration admin http://controller:8004/v1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne cloudformation public http://controller:8000/v1
  openstack endpoint create --region RegionOne cloudformation internal http://controller:8000/v1
  openstack endpoint create --region RegionOne cloudformation admin http://controller:8000/v1
  openstack domain create --description 'Openstack Heat projects and users' heat
  openstack user create --domain heat --password cloud heat_domain_admin
  openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
  openstack role create heat_stack_owner
  openstack role add --project demo --user demo heat_stack_owner
  openstack role create heat_stack_user
  echo ================================== done heat ======================================
}

function magnum-auth {
  echo ================================== start magnum ======================================
  openstack user create --domain default --password-prompt magnum
  openstack role add --project service --user magnum admin
  openstack service create --name magnum  --description 'OpenStack Container Infrastructure Management Service' container-infra
  openstack endpoint create --region RegionOne container-infra public http://CONTROLLER_IP:9511/v1
  openstack endpoint create --region RegionOne container-infra internal http://CONTROLLER_IP:9511/v1
  openstack endpoint create --region RegionOne container-infra admin http://CONTROLLER_IP:9511/v1
  openstack domain create --description "Owns users and projects created by magnum" magnum
  openstack user create --domain magnum --password-prompt magnum_domain_admin
  openstack role add --domain magnum --user-domain magnum --user magnum_domain_admin admin
  echo ================================== done magnum  ======================================
}

echo some of the functions defined here are brain-dead ... just cut-n-paste into the CLI shell

echo to change a user password:
echo pwdchange user oldpwd newpwd

# keystone-auth -v
# glance-auth -v
# cinder-auth -v
# nova-auth -v
# neutron-auth -v
  heat-auth -v
# magnum-auth -v

