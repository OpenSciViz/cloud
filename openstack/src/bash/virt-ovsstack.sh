#!/bin/sh
invoke=$_
string="$0"
echo sysboot.sh ... \"$invoke\" and \"$string\"

subshell=${string//[-._]/}
echo "subshell == $subshell"

if [ "$subshell" != "bash" ]; then
  echo "$invoke" must be sourced
  echo try: \"'. '${invoke}\" ... or: \"source ${invoke}\"
  exit
fi

vcpu=8
vram=16384 # 8192 # 1024 # 2048

bridge0=ovsbr0
bridge1=ovsbr1

vmpath=`pwd`/VMs
ovsstack=ovsstack-64g-centos7
vdisk=${vmpath}/vdbCentOS-7-CinderLVM.qcow2v3

function vreset {
  if [ $2 ] ; then vcpu="$2" ; fi
  if [ $3 ] ; then vram="$3" ; fi

  virsh destroy ${ovsstack}-ram${vram}-cpu${vcpu} ; virsh undefine ${ovsstack}-ram${vram}-cpu${vcpu}
  docker rm -f fitness gitlab registry portainer

  systemctl stop NetworkManager
  systemctl stop docker
  virsh net-destroy $bridge0 >& /dev/null
  virsh net-undefine $bridge0 >& /dev/null
  systemctl stop libvirtd

# ifdown-ovs $bridge0
  systemctl restart openvswitch
  systemctl restart ovn-controller
  /etc/sysconfig/network-scripts/ifup-ovs $bridge0
# ovs-vsctl add-br $bridge0
# ip addr add dev $bridge0 172.17.0.1/12
# ip addr add dev $bridge0 63.141.239.91/29

  systemctl restart iptables
# iptables-restore < docker_$bridge_iptables_fitness_registry_portainer_gitlab_cockpit

  systemctl start libvirtd
# virsh net-create ${bridge0}.xml
# virsh net-define ${bridge0}.xml
# virsh net-autostart $bridge0
# virsh net-start $bridge0
  virsh net-list
  virsh net-info $bridge0

  systemctl start docker

  ip a
  iptables-save
}

function vkill {
  virsh undefine $ovsstack ; virsh destroy $ovsstack
  systemctl restart libvirtd
}

function virt-ovsstack {
  vm=${ovsstack}
  if [ $1 ] ; then vm="$1" ; fi
  if [ $2 ] ; then vcpu="$2" ; fi
  if [ $3 ] ; then vram="$3" ; fi

  ovs-vsctl list-br
  if [ $? != 0 ] ; then
    echo ovs bridge not configured ... $bridge0 $bridge1
    return
  fi
  
  ovs-vsctl show
  if [ $? != 0 ] ; then
    echo ovs bridge not configured ... $bridge0 $bridge1
    return
  fi

  vname=${vm}-ram${vram}-cpu${vcpu}
  qcow=${vmpath}/${vm}.qcow2

  echo "CPUs: $vcpu" "RAM: $vram" $qcow
  virt-install --import --noautoconsole --cpu host --connect qemu:///system --ram=${vram} --name=${vname} --vcpus=${vcpu} \
               --os-type=linux --os-variant=rhel7 --network=network:${bridge0} --network=network:${bridge1} \
               --disk path=${qcow},device=disk,bus=virtio,format=qcow2 --disk path=${vdisk},device=disk,bus=virtio,format=qcow2

  virsh list
# virsh attach-interface --domain $vname --type network --model virtio --config --live # --source $qcow 
# virsh attach-device ovsstack-64g-centos7-ram16384-cpu8 ./vdb.xml
  virsh domiflist $vname
}

#vreset -v
#vkill -v
virt-ovsstack $ovsstack

######################################################

scmId=$Id$
