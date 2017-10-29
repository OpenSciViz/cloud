#!/bin/sh
# https://docs.openstack.org/magnum/latest/user/index.html#swarm
# There are two types of servers in the Swarm cluster: managers and nodes. 
# The Docker daemon runs on all servers. On the servers for manager, the Swarm manager is run
# as a Docker container on port 2376 and this is initiated by the systemd service swarm-manager.
# Etcd is also run on the manager servers for discovery of the node servers in the cluster.
# On the servers for node, the Swarm agent is run as a Docker container on port 2375 and this is 
# initiated by the systemd service swarm-agent. On start up, the agents will register themselves
# in etcd and the managers will discover the new node to manage.

invoke=$_
string="$0"
#echo sysboot.sh ... \"$invoke\" and \"$string\"

echo any change to the system controller IP must be propogated in:
echo /etc/hosts /etc/heat/heat.conf /etc/nova/nova.conf my.cnf.d/openstack.cnf /etc/cinder/cinder.conf 

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
export OS_PASSWORD=oct2017cloud
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

env| egrep 'BASH|OS_'

echo wget https://fedorapeople.org/groups/magnum/fedora-atomic-ocata.qcow2
echo openstack image create --disk-format=qcow2 --container-format=bare --file=fedora-atomic-ocata.qcow2 --property os_distro='fedora-atomic' FedoraAtomic-oct2017

vmimg=FedoraAtomic-oct2017 # centos-atomic vs. fedora-atomic-ocata
netwk=swarm-public  # provider # public
dns=8.8.8.8
mflav=1cpu-1gram-10gvol # master server flavor
flav=2cpu-2gram-10gvol # node flavor
mcnt=1 # master server count (server == VM instance with container ?)
ncnt=2 # node count (node == VMs with container instances?)

function swarm-netwk {
  openstack network create $netwk --provider-network-type flat --external --project service
  openstack subnet create ${netwk}-subnet --network swarm-public --subnet-range 192.168.1.0/24 --gateway 192.168.1.1 --ip-version 4
}

function swarm-create {
  sname=swarm-cluster
  if [ $1 ] ; then sname="$1" ; fi

  magnum cluster-template-create --image $vmimg --keypair mykey --external-network $netwk --dns-nameserver $dns --master-flavor $mflav --flavor $flav --coe swarm ${sname}-template

  magnum cluster-create --cluster-template ${sname}-template --master-count $mcnt --node-count $ncnt $sname

  mkdir myclusterconfig
  eval $(magnum cluster-config $sname --dir myclusterconfig)
}

magnum cluster-template-list
magnum cluster-list
magnum cluster-show swarm-cluster

echo test swarm-cluster via: docker run busybox echo "Hello from Docker Swarm-mode via Openstack Magnum!"

echo to create the swarm-cluster: swarm-create
echo to destroy the swarm-cluser: magnum cluster-delete swarm-cluster
echo to destroy the template:     magnum cluster-template-delete swarm-cluster-template

