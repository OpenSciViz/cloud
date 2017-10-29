#!/usr/bin/env python

import pexpect

# http://libguestfs.org/virt-sysprep.1.html
# http://libguestfs.org/virt-builder.1.html#users-and-passwords
 
qcow = 'Fedora-Cloud-Base-26-1.5.x86_64.qcow2'

pexpect.run("virt-sysprep -a Fedora-Cloud-Base-26-1.5.x86_64.qcow2 --root-password password:cloudcloud")
pexpect.run("virt-sysprep -a Fedora-Cloud-Base-26-1.5.x86_64.qcow2 --password fedora:password:cloudcloud")

# pexpect.run("virt-sysprep -a Fedora-Cloud-Base-26-1.5.x86_64.qcow2 --firstboot-command 'useradd -m -p \"\" hon ; chage -d 0 hon'")
pexpect.run("virt-sysprep -a Fedora-Cloud-Base-26-1.5.x86_64.qcow2 --firstboot-command 'useradd -m -p \"\" hon'")

