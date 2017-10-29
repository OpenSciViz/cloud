#!/bin/sh

ovsbridge=ovsbr0
rootpath=`pwd`

mocata=mothershipCentos7-ocata
vdisk=vdbCentOS-7.qcow2v3
vcpu=8
vram=16384 # 8192 # 1024 # 2048

function vreset {
  if [ $1 ] ; then ovsbridge="$1" ; fi
  if [ $2 ] ; then vcpu="$2" ; fi
  if [ $3 ] ; then vram="$3" ; fi

  virsh destroy ${movs}-ram${vram}-cpu${vcpu} ; virsh undefine ${movs}-ram${vram}-cpu${vcpu}
  virsh destroy ${mokolla}-ram${vram}-cpu${vcpu} ; virsh undefine ${mokolla}-ram${vram}-cpu${vcpu}
  docker rm -f fitness gitlab registry portainer

  systemctl stop NetworkManager
  systemctl stop docker
  virsh net-destroy $bridge >& /dev/null
  virsh net-undefine $bridge >& /dev/null
  systemctl stop libvirtd

  /etc/sysconfog/network-scripts/ifdown-ovs ifcfg-${ovsbridge}
  systemctl restart openvswitch
  systemctl restart ovn-controller
  /etc/sysconfog/network-scripts/ifup-ovs ${ovsbridge}
# ovs-vsctl add-br $bridge
# ip addr add dev $bridge 172.17.0.1/12
# ip addr add dev $bridge 63.141.239.91/29

  systemctl restart iptables
# iptables-restore < docker_$bridge_iptables_fitness_registry_portainer_gitlab_cockpit

  systemctl start libvirtd
  virsh net-create ${ovsbridge}.xml
  virsh net-list
  virsh net-info $ovsbridge

  systemctl start docker

  ip a
  iptables-save
}

function vkill {
  virsh undefine $mocata ; virsh destroy $mocata
  systemctl restart libvirtd
}

function virtmother {
  vm=${movs}
  if [ $1 ] ; then vm="$1" ; fi
  if [ $2 ] ; then vcpu="$2" ; fi
  if [ $3 ] ; then vram="$3" ; fi

  bridge=$ovsbridge
  bridge=`ovs-vsctl list-br`
  if [ $? != 0 ] ; then
    echo ovs bridge not configured ... $bridge
    return
  fi
  
  ovs-vsctl list-ports $bridge
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
# virsh attach-interface --domain ${vname} --type network --model virtio --config --live # --source $qcow 
# virsh domiflist $vname
}

#vreset -v
#vkill -v
virtmother $mocata

######################################################

scmId=$Id$
