#!/usr/bin/bash
#
# http://www.unixarena.com/2015/12/how-to-clone-a-kvm-virtual-machines-and-reset-the-vm.html
# the above describes virt-sysprep options which may be of use too ...

os=`uname|cut -c1-6`
echo "OS name $os"

export ISO_MNT_PATH=/mnt/iso/
export NEW_ISO_PATH=/var/tmp/

function isomnt {
  imgpath=${HOME}/KVMimages/CentOS-6.8-x86_64-LiveCD.iso
  if [ $1 ] ; then imgpath="$1" ; fi

  imgname=$(basename ${imgpath%.*})
  ext=$(basename ${imgpath##*.})
  echo $imgpath $imgname $ext

  if [ $ext != 'iso' ] ; then
    echo "$ext !== iso ... abort"
    return
  fi

  mntpath=/mnt/iso/${imgname}
  mkdir -p $mntpath >& /dev/null
  if [ -e $mntpath ] ; then
    echo "mount -t iso9660 -o loop $imgpath $mntpath"
    mount -t iso9660 -o loop $imgpath $mntpath
  fi
  ISO_MNT_PATH=$mntpath
  echo ls of $ISO_MNT_PATH ...
  \ls -al ${ISO_MNT_PATH}/..
  file $ISO_MNT_PATH
}

function isoinject {
  imgpath=${HOME}/KVMimages/CentOS-6.8-x86_64-LiveCD.iso
  if [ $1 ] ; then imgpath="$1" ; fi

  # mount the iso
  isom=isomnt $imgpath

  # presumaby $injection has been populated viw make install or some such, --prefix=$injection
  injection=/var/tmp/inject
  if [ $2 ] ; then injection="$2" ; fi
  if [ ! -e $injection ] ; then
    echo injection content for ISO does not exist?
    return
  fi

  newiso=/var/tmp/isoinject
  if [ ! -e $newiso ] ; then
    \mkdir -p $newiso
  fi

  cp -a $isom $newiso
  rsync -val $injection/* $newiso
  NEW_ISO_PATH=$newiso
}

origiso=imgpath=${HOME}/KVMimages/CentOS-6.8-x86_64-LiveCD.iso
if [ $1 ] ; then origiso="$1" ; fi

inject=/var/tmp/inject
if [ $2 ] ; then inject="$2" ; fi

isoinject $origiso $inject
customiso=/var/tmp/new_custom.iso
if [ $3 ] ; then customiso="$3" ; fi

iso_opt='-ldots -allow-multidot -max-iso9660-filenames -iso-level 4 -file-mode 755'
iso_opt='-r -ldots -allow-multidot -max-iso9660-filenames -iso-level 4'
geneisoimage $iso_opt -o $customiso $NEW_ISO_PATH
\ls -al $customiso
file $customiso
