#!/bin/sh


invoke=$_
string="$0"
#echo sysboot.sh ... \"$invoke\" and \"$string\"

echo any change to the system controller IP must be propogated in:
echo /etc/hosts /etc/nova/nova.conf my.cnf.d/openstack.cnf /etc/cinder/cinder.conf 

subshell=${string//[-._]/}
# echo "subshell == $subshell"

if [ "$subshell" != "bash" ]; then
  echo "$invoke" must be sourced
  echo try: \"'. '${invoke}\" ... or: \"source ${invoke}\"
  exit
fi

export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=cloud
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

env| egrep 'BASH|OS_'

function imgcreate {
  name=centos-7-generic-cloud-01aug2017
  if [ $1 ] ; then name="$1" ; fi
  qcow=`pwd`/CentOS-7-x86_64-GenericCloud.qcow2
  if [ $2 ] ; then qcow="$2" ; fi
  openstack image list
  echo openstack image create $name --file $qcow --disk-format qcow2 --container-format bare --public
  openstack image create $name --file $qcow --disk-format qcow2 --container-format bare --public
  openstack image list
}

function flavors {
  openstack flavor list
# echo $flavor2 $imgName $externalId $instanceExt
# m2.nano2 centos7-with-console 50e33cdc-89ac-4cbb-8b33-71c86646fae4 ext-centos7-m2.nano2
}

function networks {
  openstack subnet list
  openstack network list
}

# imgcreate

flavors
networks

netId=50e33cdc-89ac-4cbb-8b33-71c86646fae4
flavorName=m2.nano2
imgName=centos-7-generic-cloud-01aug2017
instanceName=hon-centos7-01sep2017

openstack server create --flavor $flavorName --image $imgName --nic net-id=$netId --security-group default --key-name mykey $instanceName
openstack server list

