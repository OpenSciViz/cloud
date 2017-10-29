#!/bin/sh
qcow=no-initCentOS-7-x86_64-GenericCloud-1708.qcow2
guestfish -a $qcow -i ln-sf /dev/null /etc/systemd/system/cloud-init.service
virt-ls -a $qcow -R /lib/systemd/system

