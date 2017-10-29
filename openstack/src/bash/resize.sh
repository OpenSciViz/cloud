function resize {
  newqcow=packstack-64g-centos7.qcow2
  qcow=/home/hon/jul2017/openstack/origVM/packstack-default-centos7.qcow2
  virt-filesystems --long -h --all -a $qcow 
  echo assume above shows /dev/sda1
  fdev=/dev/sda1
  truncate -r $qcow $newqcow
  truncate -s 64G $newqcow
  virt-resize --expand $fdev $qcow $newqcow
}

function create64 {
  fdev=/dev/sda1
  qcow=/home/hon/jul2017/openstack/origVM/packstack-default-centos7.qcow2
  qemu-img create -f qcow2 -o preallocation=metadata new.qcow2 64G
  virt-resize --expand $fdev $qcow new.qcow2
}

function vmsave {
  vcpu=8
  if [ $3 ] ; then vcpu="$3" ; fi

  vram=8192 # 1024 # 2048
  if [ $4 ] ; then vram="$4" ; fi

  if [ $1 ] ; then echo "CPUs: $vcpu" "RAM: $vram" $qcow2 ; fi

  vname=Centos-7-ram${vram}-cpu${vcpu}

  virsh managedsave $vname --bypass-cache --paused
  virsh list
}


#resize packstack-64g-centos7.qcow2
create64 packstack-64g-centos7.qcow2

######################################################

scmId=$Id$
