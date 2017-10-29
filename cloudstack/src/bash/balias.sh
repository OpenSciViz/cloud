#!/usr/bin/bash
#
os=`uname|cut -c1-6`
echo "OS name $os"

if [[ $os == Linux ]] ; then
  alias py2venv='\virtualenv -p /opt/bin/python2.7 --clear --always-copy --prompt=py2env'
  alias py3venv='\virtualenv -p /opt/bin/python3.5 --clear --always-copy --prompt=py3env'
else # assume MAC OS
  alias py2venv='/Library/Frameworks/Python.framework/Versions/2.7/bin/virtualenv -p /Library//Frameworks/Python.framework/Versions/2.7/bin/python --clear --always-copy --prompt=py2env'
  alias py3venv='/Library/Frameworks/Python.framework/Versions/3.5/bin/virtualenv -p /Library//Frameworks/Python.framework/Versions/3.5/bin/python3 --clear --always-copy --prompt=py3env'
fi

# python 2 virtualenv
alias usepy2='\pushd ${HOME} && source py2env/bin/activate ; popd'
# python 3 virtualenv
alias usepy3='\pushd ${HOME} && source py3env/bin/activate ; popd'

alias tcpstat='netstat -np tcp'

# virtualbox:
alias vls='vboxmanage list vms -l'
alias vlsr='vboxmanage list runningvms -l'
# note that adding nic2 requires "powered-off" VM (todo -- function version of alias with nic# and vmname args):
alias vaddnic2="vboxmanage modifyvm Win8.1Samba4 --nic2 hostonly --cableconnected2 on --nictype2 82540EM --hostonlyadapter2 'vboxnet0'"
alias vaddnic3="vboxmanage modifyvm Win8.1Samba4 --nic3 hostonly --cableconnected3 on --nictype2 82540EM --hostonlyadapter3 'vboxnet0'"
# vagrant:
alias vup='vagrant up'
alias vrm='vagrant destroy'
alias vsusp='vagrant suspend'
alias vhalt='vagrant halt'
alias vssh='vagrant ssh'
#
alias tarmar='pushd ~/mar2016 ; tar zcvf mar06VMs.tgz VMs/{*sh,*md,centos67_192.168.33.10-20-30/*.rb} ; popd'
alias hedt='seamonkey -editor'
alias ttyhis='script ~/ttyhis/`tty|sed "s/\///g"`'
alias nw=/opt/nwjs/nw
#
alias gitini='git clone'
alias gitags='git describe --tags `git rev-list --tags` | head'
alias gitci='git commit -a -m"more prose and/or code edits"; git push'
#alias git1='git clone --depth 1' ... see git1 func below

# need function that traverses pool-list and lists volumes
alias kvmls='virsh list && virsh pool-list'

function git1 {
  if [ ! $1 ] ; then
    echo please provide clonable git URL ... abort.
    return
  fi
  echo clone $1
  git clone $1 --depth 1
}

function gitbr {
  if [ ! $1 ] ; then
    echo please provide branch name ... abort
    return
  fi
  git branch --set-upstream-to=origin/$1
  git pull
}

function nistime {
  nt=`nc time.nist.gov 13 < /dev/null 2>&1 | grep NIST| awk '{print $2, $3}'`
  echo "nist.time.gov: $nt"

  if [ "$nt" == "" ] ; then
    yy='yy' ; mm='mm' ; dd='dd' ; HH='HH' ; MM='MM' ; SS='SS'
  else
    yy=`echo $nt| cut -c 1,2` ; mm=`echo $nt| cut -c 4,5` ; dd=`echo $nt| cut -c 7,8`
    HH=`echo $nt| cut -c 10,11` ; MM=`echo $nt| cut -c 13,14` ; SS=`echo $nt| cut -c 16,17`
  fi
  ltu=`date -u '+%y-%m-%d %H:%M:%S'`
  lt=`date '+%y-%m-%d %H:%M:%S'`
  echo NIST time = $nt UTC
  echo Host time = $ltu UTC \($lt $host local timezone\)
  uid=`id | awk '{print $1}'`
  rid=`id root | awk '{print $1}'`
  if [ "$ltu" != "$nt" ] ; then
    if [ "$uid" != "$rid" ] ; then
      echo As root reset time via: date -u $mm$dd$HH$MM$yy.$SS
    else
      date -u $mm$dd$HH$MM$yy.$SS > /dev/null 2>&1
    fi
  fi
}

# try nistime
nistime

if [[ $os != Linux ]] ; then
  echo the above should work for both MAC OS and Linux, below is just Linux stuff ...
  return
fi

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
function mntest {
  mkdir -p ${HOME}/KVMimages >& /dev/null

  echo '1st test should fail'
  touch ${HOME}/KVMimages/foo.bar
  isomnt ${HOME}/KVMimages/foo.bar

  echo '2nd test should fail'
  touch ${HOME}/KVMimages/foobar.iso
  isomnt ${HOME}/KVMimages/foobar.iso

  # default should work
  echo '3rd test should succeed (defaults)'
  isomnt

  echo '4rd test should succeed (non-defaults)'
  isomnt ${HOME}/KVMimages/SL-67-x86_64-2015-08-25-LiveMiniCD.iso
}

mntest
