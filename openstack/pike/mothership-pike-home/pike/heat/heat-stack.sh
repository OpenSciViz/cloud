#!/bin/sh

function heat-validate {
  yml=01ibm.yml
  if [ $1 ] ; then yml="$1" ; fi

  openstack orchestration template validate -t $yml 
} 

function heat-stack {
  op=list # or create or show or delete
  if [ $1 ] ; then op="$1" ; fi

  if [[ $op == list ]] ; then
    openstack stack list
    return
  fi

  name=teststack
  if [ $2 ] ; then name="$2" ; fi

  if [[ $op != create ]] ; then
    openstack stack $op $name
    return
  fi

  hot=stacktest.yml
  if [ $3 ] ; then hot="$3" ; fi

  openstack stack create -t $hot $name
  openstack stack show $name
  openstack server list | egrep $name
}

for y in $(\ls -1 *.yml) ; do
  echo $y
  heat-validate $y
done

