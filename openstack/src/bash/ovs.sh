#!/bin/sh

function ovslist {
  ovs-vsctl show
  ovs-vsctl list-ifaces ovsbr0
  ovs-vsctl list-ports ovsbr0
}

function ovsrm {
  ovs-vsctl del-port ovsbr0 vnet0
  ovs-vsctl del-port ovsbr0 vnet1
}

ovslist -v
#ovsrm -v

######################################################

scmId=$Id$
