#!/bin/bash
# https://access.redhat.com/articles/2191331 -- Basic SELinux Troubleshooting in CLI (mar 2016)
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Managing_Confined_Services/sect-Managing_Confined_Services-MySQL-Booleans.html
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Security-Enhanced_Linux/sect-Security-Enhanced_Linux-SELinux_Contexts_Labeling_Files-Persistent_Changes_semanage_fcontext.html
# https://github.com/TresysTechnology/refpolicy-contrib
# http://linux.die.net/man/8/dnsmasq_selinux
# https://github.com/TresysTechnology/refpolicy
# http://linux.die.net/man/8/libvirt_selinux
# http://linux.die.net/man/8/mysqld_selinux
# http://linux.die.net/man/8/java_selinux
# http://linux.die.net/man/8/xauth_selinux
# http://linux.die.net/man/8/automount_selinux 

function systatus {
  \mount && \df -h
  sestatus $1
  ps -eZ | egrep 'mysqld|nfs|java|iptabl|qemu|virt'
  semanage boolean -l | egrep 'mysqld|nfs|java|iptabl|qemu|virt'
# seinfo -x /etc/selinux/targeted/policy/policy.24
  if [ "$1" == '-v' ] ; then
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
  setsebool -P allow_mount_anyfile on

  setsebool -P httpd_can_network_connect on
  setsebool -P httpd_enable_homedirs on
  setsebool -P httpd_use_nfs on

  setsebool -P qemu_use_nfs on
  setsebool -P rsync_use_nfs on

  setsebool -P virt_use_nfs on
  setsebool -P virt_use_xserver on
}

function seports {
  echo allow cloudstack ports
  semanage port -a -t ssh_port_t -p tcp 22
  semanage port -a -t dns_port_t -p tcp 53
  semanage port -a -t http_port_t -p tcp 80
  semanage port -a -t http_port_t -p tcp 111
  semanage port -a -t http_port_t -p tcp 860
  semanage port -a -t ssh_port_t -p tcp 443
  semanage port -a -t nfs_port_t -p tcp 2049
  semanage port -a -t nfs_port_t -p udp 2049
  semanage port -a -t http_port_t -p tcp 3260
  semanage port -a -t ssh_port_t -p tcp 3922
  semanage port -a -t http_port_t -p tcp 7080
  semanage port -a -t http_port_t -p tcp 8080
  semanage port -a -t http_port_t -p tcp 8096
  semanage port -a -t http_port_t -p tcp 8250
  semanage port -a -t ssh_port_t -p tcp 8443
  semanage port -a -t http_port_t -p tcp 8787
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
  semanage port -a -t http_port_t -p tcp 45219
}

function selinux {
  echo selinux permit cloudstack and its deps
  sebools -v
  seports -v

  echo permissive mode for automount, dnsmasq, java, mount, mysql, nfs, qemu, virt, xauth
  semanage permissive -a automount_t
  semanage permissive -a dnsmasq_t
  semanage permissive -a java_t
  semanage permissive -a mount_t
  semanage permissive -a mysqld_t
  semanage permissive -a nfsd_t
  semanage permissive -a qemu_t
  semanage permissive -a virtd_t
  semanage permissive -a xauth_t

  echo make sure selinux allows mysql i/o:
  semanage fcontext -a -t mysqld_db_t "/var/lib/mysql/*"
  semanage fcontext -a -t mysqld_db_t "/var/lib/mysql(/.*)?"

  echo make sure selinux allows nfs rw:
  semanage fcontext -a -t nfsd_rw_t "/export/*"

  echo for automounted home "directories that need to be shared by NFS" ...
  echo as described in the Gotchas section of https://wiki.centos.org/HowTos/SELinux
  semanage fcontext -a -t public_content_rw_t "/home/*"

  restorecon -rv /
}

echo current system security status
systatus

echo set some selinux system security status
selinux -v

se=`getenforce`
echo "SELinux == $se"
if [[ $se == Permissive ]] ; then setenforce 1 ; fi 
echo '------------------------'

echo set system security status
# systatus -v
systatus

