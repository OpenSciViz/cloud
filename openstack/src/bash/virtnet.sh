#!/bin/sh
virsh net-define ovsbr0.xml 
virsh net-define ovsbr1.xml 
virsh net-autostart ovsbr1
virsh net-autostart ovsbr0
virsh net-start ovsbr0
virsh net-start ovsbr1
virsh net-info ovsbr1
virsh net-info ovsbr0

######################################################

scmId=$Id$
