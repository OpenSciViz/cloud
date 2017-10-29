#!/bin/sh

bridge0=ovsbr0
vcpu=8
vram=16384 # 8192 # 1024 # 2048

rootpath=`pwd`

packstack=centos7-ovspackstack-mothership
vdisk=vdbCentOS-7.qcow2v3

function vreset {
  if [ $2 ] ; then vcpu="$2" ; fi
  if [ $3 ] ; then vram="$3" ; fi

  virsh destroy ${movs}-ram${vram}-cpu${vcpu} ; virsh undefine ${movs}-ram${vram}-cpu${vcpu}
  virsh destroy ${mokolla}-ram${vram}-cpu${vcpu} ; virsh undefine ${mokolla}-ram${vram}-cpu${vcpu}
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
  virsh net-create ${bridge0}.xml
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
  virsh undefine $packstack ; virsh destroy $packstack
  systemctl restart libvirtd
}

function virt-packstack {
  vm=${packstack}
  if [ $1 ] ; then vm="$1" ; fi
  if [ $2 ] ; then vcpu="$2" ; fi
  if [ $3 ] ; then vram="$3" ; fi

  bridge=`ovs-vsctl list-br`
  if [ $? != 0 ] ; then
    echo ovs bridge not configured ... $bridge
    return
  fi
  if [ $bridge != $bridge0 ] ; then
    echo $bridge0 not configured ... $bridge
    return
  fi
  
  ovs-vsctl list-ports $bridge0
  if [ $? != 0 ] ; then
    echo ovs bridge not configured ... $bridge
    return
  fi

  vname=${vm}-ram${vram}-cpu${vcpu}
  qcow=${rootpath}/${vm}.qcow2

  echo "CPUs: $vcpu" "RAM: $vram" $qcow
  virt-install --import --noautoconsole --cpu host --connect qemu:///system --ram=${vram} --name=${vname} --vcpus=${vcpu} \
               --os-type=linux --os-variant=rhel7 --network=network:${bridge} --network=network:${bridge} \
               --disk path=${qcow},device=disk,bus=virtio,format=qcow2 # --disk path=${vdisk},device=disk,bus=virtio,format=qcow2

  virsh list
  virsh domiflist $vname
}

#vreset -v
#vkill -v
virt-packstack $packstack

#virsh attach-interface --domain $vname --type network --model virtio --config --live # --source $qcow 
#virsh domiflist $vmname

######################################################

scmId=$Id$
