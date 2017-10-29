#!/bin/sh
zpoolnames=`zpool status|grep 'pool\:'|awk '{print $2}'`
zpool1=`zpool status|grep 'pool\:'|head -1|awk '{print $2}'`
zpool status $zpool1
zfs get compression $zpool1
zfs get sharenfs $zpool1
zfs get sharesmb $zpool1
