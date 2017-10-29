#!/bin/sh
source admin-openrc

name=atomichost-with-console
filename=atomic-console.qcow2

function imginstall {
  name=atomichost-with-console
  if [ $1 ] ; then name="$1" ; fi
  filename=atomic-console.qcow2
  if [ $2 ] ; then filename="$2" ; fi

  openstack image create $name --file $filename --disk-format qcow2 --container-format bare --public
  openstack image list
}

openstack image list
if [ $? != 0 ] ; then
  systemctl status openstack-glance-api.service openstack-glance-registry.service
  echo please ensure the openstack image service \(glance\) is UP
  exit 
fi

imginstall $name $filename
