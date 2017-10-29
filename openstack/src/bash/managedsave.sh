#!/bin/sh

virsh managedsave packstack-64g-centos7-ram16384-cpu8 --bypass-cache --paused
virsh undefine packstack-64g-centos7-ram16384-cpu8 --managed-save
virsh managedsave ovsstack-64g-centos7-ram16384-cpu8 --bypass-cache --paused
virsh undefine ovsstack-64g-centos7-ram16384-cpu8 --managed-save

######################################################

scmId=$Id$
