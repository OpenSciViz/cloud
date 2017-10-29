#!/bin/sh

function ovsbuild {
  ./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-linux=/lib/modules/$(uname -r)/build

  make
}

function ovsstat {
  systemctl status openvswitch
  systemctl status ovn-controller
  systemctl status ovs-vswitchd
  systemctl status ovsdb-server
}

function ovsinstall {
  systemctl stop openvswitch
  systemctl stop ovn-controller

  make install

  systemctl restart openvswitch
  systemctl restart ovn-controller
}

function ovsreset {
  ovs-vsctl emer-reset
  systemctl restart openvswitch
  systemctl restart ovn-controller
}

ovsstat -v

