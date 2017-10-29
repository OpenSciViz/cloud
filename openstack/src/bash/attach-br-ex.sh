#!/bin/sh

vm=instance-0000000f
virsh attach-interface --domain $vm --type network --source br-ex --model virtio --config --live
ip address add 172.17.0.20 dev vnet0

vm=instance-0000000e
virsh attach-interface --domain $vm --type network --source br-ex --model virtio --config --live
ip address add 172.17.0.21 dev vnet1
