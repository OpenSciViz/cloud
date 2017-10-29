#!/bin/sh
alias gitsno='\git -c http.sslVerify=false'
alias gitini='git clone --recursive'
alias gitags='git describe --tags `git rev-list --tags|head`'
alias gitagco='tag=`git rev-list --tags | head -1` && tag=`git describe --tags $tag` && git checkout $tag && echo $tag'
alias gitci='git commit -a -m"more prose and/or code edits"; git push'
alias gitrsync='rsync -val --exclude=".git" '
alias mkdir='\mkdir -p'

function gitmpush {
  # optionally provide Jira task-issu Id commit and push info
  if [[ $1 == -m ]] ; then
    if [ "$2" != "" ] && [ "$3" != "" ] ; then
      git commit -m "$2 #comment $3" .
    elif [ "$2" != "" ] ; then
      git commit -m "CLOUD-10 #comment $2" .
    else
      git commit -m 'update master branch' .
    fi
  fi
  git push -u origin master
  cwd=`pwd` ; base=$(basename $cwd) ; rsyncto=None
  echo 'current working directory is: '
  echo $cwd ... $basename
  read -p 'rsync this? (enter full destination ala [[user@]hostname:]/path/to/destiny) [no]: ' usrinp
  if [ "$usrinp" != "" ] ; then
    echo "usrinp == $usrinp" 
    rsyncto="$usrinp"
    echo need to double check the rsync destination syntax and accept or reject it ...
  fi
  if [[ $rsyncto == None ]] ; then
    echo rsync NOT requested OR bad syntax ... all done
    return
  fi
  echo attempt to rsync $cwd to $rsyncto
  \mkdir -p $rsyncto >& /dev/null 
  if [ $? == 0 ] ; then
    pushd ..
    gitrsync $base $rsyncto
    popd
  fi
}

