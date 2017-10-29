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
bridge2=ovsbr2

vmpath=`pwd`/VMs
generic=CentOS-7-x86_64-GenericCloud-1708
vdisk=${vmpath}/vdbCentOS-7-CinderLVM.qcow2v3

function vreset {
  if [ $2 ] ; then vcpu="$2" ; fi
  if [ $3 ] ; then vram="$3" ; fi

  virsh destroy ${generic}-ram${vram}-cpu${vcpu} ; virsh undefine ${generic}-ram${vram}-cpu${vcpu}
  docker rm -f fitness gitlab registry portainer

  systemctl stop NetworkManager
  systemctl stop docker
  ovs-vsctl emer-reset
  virsh net-destroy $bridge >& /dev/null
  virsh net-undefine $bridge >& /dev/null
  systemctl stop libvirtd

# ifdown-ovs $bridge0
  systemctl restart openvswitch
  systemctl restart ovn-controller
  /etc/sysconfig/network-scripts/ifup-ovs $bridge0
# ovs-vsctl add-br $bridge
# ip addr add dev $bridge 172.17.0.1/12
# ip addr add dev $bridge 63.141.239.91/29

  systemctl restart iptables
# iptables-restore < docker_$bridge_iptables_fitness_registry_portainer_gitlab_cockpit

  systemctl start libvirtd
# virsh net-create ${bridge}.xml
# virsh net-define ${bridge}.xml
# virsh net-autostart $bridge
# virsh net-start $bridge
  virsh net-list
  virsh net-info $bridge

  systemctl start docker

  ip a
  iptables-save
}

function vkill {
  vm=${generic}
  if [ $1 ] ; then vm="$1" ; fi
  vname=${vm}-ram${vram}-cpu${vcpu}

  virsh undefine $vmname ; virsh destroy $vmname
  systemctl restart libvirtd
}

function sysprep-generic {
  vm=${generic}
  if [ $1 ] ; then vm="$1" ; fi
  if [ $2 ] ; then vcpu="$2" ; fi
  if [ $3 ] ; then vram="$3" ; fi
  vname=${vm}-vdb64g-ram${vram}-cpu${vcpu}
  qcow=${vmpath}/${vm}.qcow2

  echo reset root password and pre-create hon user account
  virt-sysprep -a ${qcow} --root-password password:cloudcloud
  virt-sysprep -a ${qcow} --firstboot-command 'useradd -m -p "" hon ; chage -d 0 hon'
}


function virt-generic {
  vm=${generic}
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

  vname=${vm}-vdb64g-ram${vram}-cpu${vcpu}
  qcow=${vmpath}/${vm}.qcow2

  echo "CPUs: $vcpu" "RAM: $vram" $qcow

  # echo create 3 vNICs eth0-2 attached to openvswitch bridge $bridge0
  echo create 3 vNICs eth0-2 attached to openvswitch bridge $bridge1 ... 

# echo try test with single ovs bridge ...
# echo shutdown $bridge0 and move 172.17.0.1 to $bridge1 
# echo ifdown $bridge0
# echo ip addr add dev $bridge1 172.17.0.1/12

# echo test with mothership vNICs attached to separate ovs bridge $bridge0
# echo ovs-vsctl set bridge $bridge0 stp_enable=true

  virt-install --import --noautoconsole --cpu host --connect qemu:///system --ram=${vram} --name=${vname} --vcpus=${vcpu} \
               --os-type=linux --os-variant=rhel7 \
               --disk path=${qcow},device=disk,bus=virtio,format=qcow2 \
               --network=network:default --network=network:default --network=network:default
             # --disk path=${vdisk},device=disk,bus=virtio,format=qcow2 \
             # --network=network:${bridge1} --network=network:${bridge1} --network=network:${bridge1} # eth0, 1, 2 all on ovsbr1
             # --network=network:${bridge0} --network=network:${bridge0} --network=network:${bridge0} # eth0, 1, 2 all on ovsbr0
             # --network=network:default --network=network:default --network=network:default # eth0, 1, 2 on virbr0 i.e. default.xml
             # --network=network:${bridge0} --network=network:${bridge1} --network=network:${bridge2} # eth0, eth1, eth2 on 3 separate bridges

  virsh list
  virsh domiflist $vname
}

function attach {
  vm=${generic}
  if [ $1 ] ; then vm="$1" ; fi
  vname=${vm}-ram${vram}-cpu${vcpu}

  bridge=${bridge0}
  if [ $2 ] ; then bridge="$2" ; fi

  echo 'create eth1 and eth2 vNICs and attached them to our OVS bridge(s)'
  virsh attach-interface --domain $vname --source $bridge --type network --model virtio --config --live 
  virsh attach-interface --domain $vname --source $bridge --type network --model virtio --config --live 

# echo /dev/vdb
# virsh attach-device $vname ./vdb.xml
}

function ovs-info {
  echo 'ref: https://blog.scottlowe.org/2012/10/04/some-insight-into-open-vswitch-configuration'
  ovs-vsctl show
  ovs-vsctl list bridge
# ovs-vsctl list interface
  ovs-vsctl list port
}

# vreset -v
# vkill -v
# sysprep-generic $generic
virt-generic $generic

######################################################

scmId=$Id$
