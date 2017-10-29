#!/bin/bash
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Managing_Confined_Services/sect-Managing_Confined_Services-MySQL-Booleans.html

function systatus {
  \mount && \df -h
  sestatus $?
  ps -eZ | egrep 'mysqld|nfs|java|iptabl|qemu|virt'
  semanage boolean -l | egrep 'mysqld|nfs|java|iptabl|qemu|virt'
# seinfo -x /etc/selinux/targeted/policy/policy.24
  if [ $? == '-v' ] ; then
   auditctl -l
   seinfo -t
   semanage port -l
   iptables -L
   sysctl -a
  fi
}

function sebools {
  echo allow java_execstack, NFS, and kvm VM guests NFS and X11
  setsebool -P allow_java_execstack on

  setsebool -P httpd_use_nfs on
  setsebool -P rsync_use_nfs on

  setsebool -P virt_use_nfs on
  setsebool -P virt_use_xserver on
}

# move all semanage stuff here:
function selinux {
  echo selinux permit cloudstack and its deps
  semanage permissive -a dnsmasq_t
  semanage permissive -a virtd_t
  semanage permissive -a java_t

  echo make sure selinux allows mysql i/o:
  semanage permissive -a mysqld_t
  semanage fcontext -a -t mysqld_db_t "/var/lib/mysql(/.*)?"

  echo allow cloudstack ports
# semanage port -a -t ssh_port_t -p tcp 22
  semanage port -a -t dns_port_t -p tcp 53
  semanage port -a -t http_port_t -p tcp 80
# semanage port -a -t http_port_t -p tcp 111
# semanage port -a -t http_port_t -p tcp 860
# semanage port -a -t ssh_port_t -p tcp 443
  semanage port -a -t nfs_port_t -p tcp 2049
  semanage port -a -t nfs_port_t -p udp 2049
# semanage port -a -t http_port_t -p tcp 3260
# semanage port -a -t ssh_port_t -p tcp 3922
# semanage port -a -t http_port_t -p tcp 7080
  semanage port -a -t http_port_t -p tcp 8080
# semanage port -a -t http_port_t -p tcp 8096
  semanage port -a -t http_port_t -p tcp 8250
  semanage port -a -t ssh_port_t -p tcp 8443
# semanage port -a -t http_port_t -p tcp 8787
  semanage port -a -t http_port_t -p tcp 9090

  echo allow some VNC ports
# VNC-clients java 5800 - 5899
  semanage port -a -t vnc_port_t -p tcp 5800
# VNC-clients standard 5900 - 6100
  semanage port -a -t vnc_port_t -p tcp 5900
  semanage port -a -t vnc_port_t -p tcp 5901
  semanage port -a -t vnc_port_t -p tcp 5902
  semanage port -a -t vnc_port_t -p tcp 5903
  semanage port -a -t vnc_port_t -p tcp 5904
  semanage port -a -t vnc_port_t -p tcp 5905
  semanage port -a -t vnc_port_t -p tcp 5906
  semanage port -a -t vnc_port_t -p tcp 5907
  semanage port -a -t vnc_port_t -p tcp 5908
  semanage port -a -t vnc_port_t -p tcp 5909

  echo allow NFS ports
# more NFS
  semanage port -a -t nfs_port_t -p tcp 20048
  semanage port -a -t nfs_port_t -p udp 20048
  semanage port -a -t nfs_port_t -p tcp 20049
  semanage port -a -t nfs_port_t -p udp 20049

# JMX console for cloudstack
# semanage port -a -t httpd_port_t -p tcp 45219
}

echo current system security status
systatus -v

# echo set some selinux system security status
# selinux -v

echo make sure yum can install / update kernels in /boot
mount -o remount, rw /boot

grep -i mysql /etc/selinux/targeted/contexts/files/file_contexts.local

# set max (debug) level selinux audit logging:
semodule -DB
# set permissive if needed:
se=`getenforce`
echo "SELinux == $se"
if [[ $se == Enforcing ]] ; then setenforce 0 ; fi 
echo '------------------------'

# given the above SELinux permissive, not sure we need this, but ...
# libvirt storage pools with NFS: https://fedoraproject.org/wiki/How_to_debug_Virtualization_problems
getsebool virt_use_nfs | grep -i off
if [ $? == 0 ] ; then
  echo enabling libvirt storage pools with NFS ... for some reason this can take a long while
  setsebool -P virt_use_nfs on
fi
getsebool virt_use_nfs
getsebool virt_use_xserver | grep -i off
if [ $? == 0 ] ; then
  echo enabling libvirt xserver ... for some reason this can take a long while
  setsebool -P virt_use_xserver on
fi
getsebool virt_use_xserver
echo '------------------------'

# http://unix.stackexchange.com/questions/78953/qemu-how-to-ping-host-network
# and http://serverfault.com/questions/414115/linux-vlans-over-bridge
ipfwd=`sysctl -a | grep 'ipv4\.ip_forward ' | awk '{print $3}'`
if [ $ipfwd -ne 1 ] ; then
  echo set ipv4 forward on
  sysctl -w net.ipv4.ip_forward=1
  sysctl -w net.ipv4.ping_group_range='0 2147483647'
  sysctl -w net.bridge.bridge-nf-filter-vlan-tagged=1
  echo above sysctls will not persist on reboot ... need to edit /etc/sysctl.conf and /etc/sysctl.d/ files ...
# sysctl -p && sysctl --system # load /etc/sysctl.conf and /end/sysctl.d/*
fi
sysctl -a|egrep 'ping_group|ip_forward |vlan\-'
echo '------------------------'

#
echo 'enabling modified rc.local for cloudstack -- be sure it no longer performs ICBR init!'
if [ ! -e /etc/rc3.d/S99local ] ; then mv /etc/rc3.d/disabled-S99local /etc/rc3.d/S99local ; fi

#
path=/export:/usr/share/cloudstack-common/vms:${PATH}
if [ $1 ] ; then path=$1:${path} ; fi

echo "unlock executables in path = $path"
for p in $(echo $path|tr ':' ' '); do find $p -type d -exec chmod a+rwx {} \; ; done
for p in $(echo $path|tr ':' ' '); do find $p -type f -executable -exec chmod a+rx {} \; ; done
#for p in $(echo $path|tr ':' ' '); do find $p -type f -executable -exec ls -alqF {} \; ; done

# cloudstack:
sysdir=/usr/share/{cloudstack-common,cloudstack-agent,cloudstack-management}
echo 'unlock (chmod) ' $sysdir
find /usr/share/{cloudstack-common,cloudstack-agent,cloudstack-management} -type d -exec chmod a+rwx {} \;
chmod -R a+rw /usr/share/{cloudstack-common,cloudstack-agent,cloudstack-management}
chown -R cloud:cloud /usr/share/{cloudstack-common,cloudstack-agent,cloudstack-management}

sysdir='/var/log/cloudstack /var/cloudstack /etc/cloudstack'
echo 'unlock (chmod) ' $sysdir
find /var/run/cloud* $sysdir -type d -exec chmod a+rwx {} \;
chmod -R a+rw /var/run/cloud* $sysdir

# evidently ssh keypair pub-private *.cloud files are hard-coded install in /root/.ssh
# unlock /mnt may not be needed, but who knows ...
sysdir='/root/.ssh /mnt'
echo 'unlock (chmod) ' $sysdir
find $sysdir -type d -exec chmod a+rwx {} \;
#chmod -R a+rw $sysdir
chmod a+rwx $sysdir/*

# when using cloudstack with kvm-libvirtd:
sysdir='/sys/devices /etc/polkit-1 /etc/libvirt /var/lib/libvirt /var/log/libvirt /var/run/libvirt'
echo 'unlock (chmod) ' $sysdir
find $sysdir -type d -exec chmod a+rwx {} \;
chmod -R a+rw $sysdir

echo current system security status
systatus -v

