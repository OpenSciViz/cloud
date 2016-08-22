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
  echo ls of $mntpath ...
  \ls -al ${mntpath}/..
  file $mntpath
}

# unit test
mkdir -p ${HOME}/KVMimages >& /dev/null

echo '1st test should fail'
touch ${HOME}/KVMimages/foo.bar
isomnt ${HOME}/KVMimages/foo.bar

echo '2nd test should fail'
touch ${HOME}/KVMimages/foobar.iso
isomnt ${HOME}/KVMimages/foobar.iso

# default should work
echo '3nd test should succeed (defaults)'
isomnt

echo '4nd test should succeed (non-defaults)'
isomnt ${HOME}/KVMimages/SL-67-x86_64-2015-08-25-LiveMiniCD.iso
