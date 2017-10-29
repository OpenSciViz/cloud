#!/bin/sh

function newsize {
  sz=32G
  if [ $1 ] ; then sz="$1" ; fi
  if [ $2 ] ; then vm="$2" ; fi

  qcow=`pwd`/${vm}.qcow2
  newq=new-${vm}.qcow2

  fdev=/dev/sda1
  qemu-img create -f qcow2 -o preallocation=metadata ${newq} $sz
  virt-resize --expand $fdev $qcow ${newq}
  \ls -alqF ${newq}
}


function vmsave {
  vcpu=8
  if [ $3 ] ; then vcpu="$3" ; fi

  vram=8192 # 1024 # 2048
  if [ $4 ] ; then vram="$4" ; fi

  if [ $1 ] ; then echo "CPUs: $vcpu" "RAM: $vram" $vm ; fi

  vname=${vm}-ram${vram}-cpu${vcpu}

  virsh managedsave $vname --bypass-cache --paused
  virsh list
}

vm=CentOS-7-x86_64-GenericCloud-1708
#vm=Fedora-Cloud-Base-26-1.5.x86_64
newsize 32G $vm

######################################################

scmId=$Id$
