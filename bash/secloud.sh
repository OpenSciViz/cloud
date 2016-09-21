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
# https://www.mankier.com/8/sge_execd_selinux and https://linux.die.net/man/8/sge_selinux
# grep sge_ /etc/services
# sge_qmaster     6444/tcp    # Grid Engine Qmaster Service
# sge_qmaster     6444/udp    # Grid Engine Qmaster Service
# sge_execd       6445/tcp    # Grid Engine Execution Service
# sge_execd       6445/udp    # Grid Engine Execution Service

function systatus {
  \mount && \df -h
  sestatus $1
  ps -eZ | egrep 'mysqld|nfs|java|iptabl|qemu|virt'
  semanage boolean -l | egrep 'mysqld|nfs|java|iptabl|qemu|virt'
# seinfo -x /etc/selinux/targeted/policy/policy.24
  if [[ $1 == -v ]] ; then
   auditctl -l
   seinfo -t
   semanage port -l
   iptables -L
   sysctl -a
  fi
}

function sebools {
  echo allow java_execstack, NFS, and kvm VM guests, X11, and SGE gridengine
  setsebool -P allow_java_execstack on
  setsebool -P allow_mount_anyfile on

  setsebool -P httpd_use_nfs on
  setsebool -P qemu_use_nfs on
  setsebool -P rsync_use_nfs on
  setsebool -P virt_use_nfs on
  setsebool -P virt_use_xserver on

  setsebool -P sge_use_nfs on
  setsebool -P sge_domain_can_network_connect on
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

# gridengine SGE ports (sge_qmaster is 6444 and sge_execd is 6445)
# https://bugzilla.redhat.com/show_bug.cgi?id=963305 mentions seg_port, but this fails ...
# semanage port -a -t sge_port_t -p tcp 6444
# semanage port -a -t sge_port_t -p udp 6444
# semanage port -a -t sge_port_t -p tcp 6445
# semanage port -a -t sge_port_t -p udp 6445
}

function sesge {
  echo setsebool -P sge_use_nfs and sge_domain_can_network_connect
  setsebool -P sge_use_nfs on
  setsebool -P sge_domain_can_network_connect on

  echo gridengine SGE ports ... sge_qmaster is 6444 and sge_execd is 6445 ...
# https://bugzilla.redhat.com/show_bug.cgi?id=963305 mentions seg_port, but this fails ...
# semanage port -a -t sge_port_t -p tcp 6444
# semanage port -a -t sge_port_t -p udp 6444
# semanage port -a -t sge_port_t -p tcp 6445
# semanage port -a -t sge_port_t -p udp 6445

  semanage permissive -a sge_execd_t
  semanage permissive -a sge_job_ssh_t
  semanage permissive -a sge_shepherd_t
  semanage permissive -a sge_job_t

  echo placeholder for sge file context settings ...
  semanage fcontext -a -t cluster_conf_t "/etc/cluster(/.*)?"

  semanage fcontext -a -t cluster_var_lib_t "/var/lib/pcsd(/.*)?"
  semanage fcontext -a -t cluster_var_lib_t "/var/lib/cluster(/.*)?"
  semanage fcontext -a -t cluster_var_lib_t "/var/lib/openais(/.*)?"
  semanage fcontext -a -t cluster_var_lib_t "/var/lib/pengine(/.*)?"
  semanage fcontext -a -t cluster_var_lib_t "/var/lib/corosync(/.*)?"
  semanage fcontext -a -t cluster_var_lib_t "/usr/lib/heartbeat(/.*)?"
  semanage fcontext -a -t cluster_var_lib_t "/var/lib/pacemaker(/.*)?"

  semanage fcontext -a -t cluster_var_run_t "/var/run/crm(/.*)?"
  semanage fcontext -a -t cluster_var_run_t "/var/run/cman_.*"
  semanage fcontext -a -t cluster_var_run_t "/var/run/rsctmp(/.*)?"
  semanage fcontext -a -t cluster_var_run_t "/var/run/aisexec.*"
  semanage fcontext -a -t cluster_var_run_t "/var/run/heartbeat(/.*)?"
  semanage fcontext -a -t cluster_var_run_t "/var/run/corosync-qnetd(/.*)?"
  semanage fcontext -a -t cluster_var_run_t "/var/run/corosync-qdevice(/.*)?"
  semanage fcontext -a -t cluster_var_run_t "/var/run/cpglockd.pid"
  semanage fcontext -a -t cluster_var_run_t "/var/run/corosync.pid"
  semanage fcontext -a -t cluster_var_run_t "/var/run/rgmanager.pid"
  semanage fcontext -a -t cluster_var_run_t "/var/run/cluster/rgmanager.sk"

  semanage fcontext -a -t root_t "/"
  semanage fcontext -a -t "/initrd"

  semanage fcontext -a -t sge_spool_t "/usr/spool/gridengine(/.*)?"

# placeholders:
  semanage fcontext -a -t sge_execd_exec_t "/usr/share/gridengine(/.*)?"
  semanage fcontext -a -t sge_job_exec_t "/usr/share/gridengine(/.*)?"
  semanage fcontext -a -t sge_shepherd_exec_t "/usr/share/gridengine(/.*)?"
  semanage fcontext -a -t sge_tmp_t "/usr/share/gridengine(/.*)?"
}

function selinux {
  echo selinux permit cloudstack and its deps
  sebools -v
  seports -v
  sesge -v

  semanage permissive -a dnsmasq_t
  semanage permissive -a java_t
  semanage permissive -a mount_t
  semanage permissive -a mysqld_t
  semanage permissive -a nfsd_t
  semanage permissive -a qemu_t
  semanage permissive -a virtd_t

  echo make sure selinux allows mysql i/o:
  semanage fcontext -a -t mysqld_db_t "/var/lib/mysql/*"
  semanage fcontext -a -t mysqld_db_t "/var/lib/mysql(/.*)?"

  echo make sure selinux allows nfs rw:
  semanage fcontext -a -t nfsd_rw_t "/export/*"

  restorecon -rv /
}

echo current system security status
systatus

# echo set some selinux system security status
# selinux -v
sesge -v

setenforce 1
se=`getenforce`
echo "SELinux == $se"
echo '------------------------'

echo set system security status
# systatus -v
systatus
