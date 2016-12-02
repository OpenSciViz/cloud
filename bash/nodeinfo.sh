#!/bin/sh
\virsh nodeinfo
\zpool status
zpool1=`zpool status|grep 'pool\:'|head -1|awk '{print $2}'`
zfs get compression $zpool1
zfs get sharenfs $zpool1
zfs get sharesmb $zpool1
#df -h | egrep -i 'map|export'
\df -h
vmstat -d

