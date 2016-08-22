function isomnt {
  imgpath=${HOME}/KVMimages/CentOS-6.8-x86_64-LiveCD.iso
  if [ $1 ] ; then imgpath="$1" ; fi

  imgname=$(basename ${imgpath%.*})
  ext=$(basename ${imgpath##*.})
  echo $imgname $ext

  if [ $ext != 'iso' ] ; then
    echo "$ext !== iso ... abort"
    exit
  fi

  mntpath=/mnt/iso/${imgname}
  mkdir -p
  mount -t iso9660 -o loop $imgpath $mntpath
  \ls -al
}

# unit test
mkdir -p ${HOME}/KVMimages >& /dev/null

touch ${HOME}/KVMimages/foo.bar
isomnt ${HOME}/KVMimages/foo.bar

touch ${HOME}/KVMimages/foobar.iso
isomnt ${HOME}/KVMimages/foobar.iso
