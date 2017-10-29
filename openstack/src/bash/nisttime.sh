#!/bin/bash
# SCM $Id$
host=`hostname`
uid=`id | awk '{print $1}'`
rid=`id root | awk '{print $1}'`

which chronyc
if [ $? == 0 ] ; then
  chrony=0
  chronyc sources
  if [ "$uid" == "$rid" ] ; then systemctl stop chronyc ; fi
else
  chrony=None
  echo no chronyc found
fi


echo trying time-d.nist.gov ...
nt=`nc -t -i 3 time-d.nist.gov 13 2>&1 | \grep NIST | \awk '{print $2, $3}'`
if [ "$nt" == "" ] ; then
  echo timeout from time-d ... trying time-c
  nt=`nc -t -i 3 time-c.nist.gov 13 2>&1 | \grep NIST | \awk '{print $2, $3}'`
fi

if [ "$nt" == "" ] ; then
  echo timeout from time-c ... trying time-b
  nt=`nc -t -i 3 time-b.nist.gov 13 2>&1 | \grep NIST | \awk '{print $2, $3}'`
fi

if [ "$nt" == "" ] ; then
  echo timeout from time-b ... trying time-a
  nt=`nc -t -i 3 time-a.nist.gov 13 2>&1 | \grep NIST | \awk '{print $2, $3}'`
fi

if [ "$nt" == "" ] ; then
  echo all timed-out ...
  yy='yy' ;  mm='mm' ;  dd='dd' ; HH='HH' ; MM='MM' ; SS='SS'
else
  yy=`echo $nt| cut -c 1,2`
  mm=`echo $nt| cut -c 4,5`
  dd=`echo $nt| cut -c 7,8`
  HH=`echo $nt| cut -c 10,11`
  MM=`echo $nt| cut -c 13,14`
  SS=`echo $nt| cut -c 16,17`
fi

ltu=`date -u '+%y-%m-%d %H:%M:%S'`
lt=`date '+%y-%m-%d %H:%M:%S'`
echo NIST time = $nt UTC
echo Host time = $ltu UTC \($lt $host local timezone\)

if [ "$ltu" != "$nt" ] ; then
  if [ "$uid" != "$rid" ] ; then
    echo As root reset time via: date -u $mm$dd$HH$MM$yy.$SS
  else
    date -u $mm$dd$HH$MM$yy.$SS 2>&1 > /dev/null
    if [ $chrony == 0 ] ; then systemctl start chronyd ; fi
  fi
fi
