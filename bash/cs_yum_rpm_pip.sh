#!/bin/sh
# assuming a minimal centos6.7 vagrant init with a single node private ip 192.168.33.10 ...
# vagrant up ... vagrant ssh ... su ...
#
# http://www.greenhills.co.uk/2015/02/23/cloudstack-4.4-single-server-on-ubuntu-14.04.1-with-kvm.html -- provides tangible scenario
#
# according to the quick install guide: http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/qig.html
# need to make sure selinux is off and we have a fully qualified domainame hostname
hostname -f
setenforce Permissive
# may also need to config setroubleshoot-server and auditd:
# https://www.server-world.info/en/note?os=CentOS_6&p=selinux&f=8 (look at CentOS 7 too)

# 'adding a host (to cluster)' was problematic using a virtualbox VM:
# "Warning ... Make sure the hypervisor host does not have any VMs already running before you add it to CloudStack." from:
# http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/configuration.html#adding-a-host-xenserver-or-kvm
# other refs:
# http://docs.cloudstack.apache.org/projects/cloudstack-administration/en/4.8/management.html
# http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/management-server/# -- note hypervisor templates (xn, kxvm, lxc)
# http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/choosing_deployment_architecture.html
#
yum update -y

# selinux, qemu-kvm and libvirt, cloudstack, and other useful dependencies (some yums require epel repo)
#yum install -y autoconf
yum install -y yum-utils yum-builddep nfs-utils pax-utils git ipset curl wget
yum install -y bridge-utils bind-utils vconfig tcpdump ntp lokkit setroubleshoot-server
yum install -y python-devel python-pip python-imaging ruby-devel db4-devel tcl-devel expat-devel
yum install -y mysql-server mysql-devel MySQL-python python27-MySQL-python mysql-connector-python nginx
yum install -y openssl-devel sqlite-devel bzip2-devel gdbm-devel ncurses-devel xz-devel readline-devel
yum install -y libxslt-devel libxml2-devel libvirt-devel libguestfs-tools-c vagrant
yum install -y qemu-kvm qemu-img qemu-kvm-tools virt-install virt-manager libvirt libvirt-python libvirt-client
# these are indicated for cloudstack-management-4.8.0-1.el6.x86_64.rpm -- even tomcat6
yum install -y ipmitool java-1.7.0-openjdk jpackage-utils mkisofs mysql-connector-java tomcat6 python-paramiko ws-commons-util
yum install -y vnc vnc-server 
yum groupinstall -y "Desktop" 
#yum groupinstall -y "X Window System" "Desktop" "Fonts" "General Purpose Desktop"
#yum groupinstall -y development virtualization-client virtualization-platform virtualization-tools

#
# after everything is installed and configured and tested, try turning SELinux back on, and troubleshoot:
yum install -y selinux-policy selinux-policy-doc setroubleshoot-doc setroubleshoot-doc policycoreutils-python

#
# try ansible someday?
# yum install -y ansible

# these are indicated for cloudstack-agent-4.8.0-1.el6.x86_64.rpm:
curl -O http://download.cloud.com/support/jsvc/jakarta-commons-daemon-jsvc-1.0.1-8.9.el6.x86_64.rpm
rpm -ivh jakarta-commons-daemon-jsvc-1.0.1-8.9.el6.x86_64.rpm
# the above rpm ensure this final yum succeeds:
yum install -y jsvc
#
pip install flask-socketio, pyinotify, scandir, six, virtualenv

#
# yum -y install cloudstack-management
# yum -y install cloudstack-agent
touch /etc/ssh/sshd_config
echo 'AllowAgentForwarding yes' >> /etc/ssh/sshd_config
echo 'AllowTcpForwarding yes' >> /etc/ssh/sshd_config
echo 'X11Forwarding yes' >> /etc/ssh/sshd_config
echo 'X11DisplayOffset 10' >> /etc/ssh/sshd_config
echo 'X11UseLocalhost no' >> /etc/ssh/sshd_config
#
# Restart the sshd daemon:
service sshd restart
yum -y update xauth
#
chkconfig ntpd on
service ntpd start
#
# from http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/management-server/ ...
# cloudstack yum repo:
touch /etc/yum.repos.d/cloudstack.repo
echo '[cloudstack]' >> /etc/yum.repos.d/cloudstack.repo
echo 'name=cloudstack' >> /etc/yum.repos.d/cloudstack.repo
echo 'baseurl=http://cloudstack.apt-get.eu/centos/6/4.8/' >> /etc/yum.repos.d/cloudstack.repo
echo 'enabled=1' >> /etc/yum.repos.d/cloudstack.repo
echo 'gpgcheck=0' >> /etc/yum.repos.d/cloudstack.repo
# nfs:
mkdir -p /mnt/{primary,secondary} /export/{primary,secondary}
touch /etc/exports
echo '/export *(rw,async,no_root_squash,no_subtree_check)'  >> /etc/exports
touch /etc/sysconfig/nfs
echo 'LOCKD_TCPPORT=32803' >> /etc/sysconfig/nfs
echo 'LOCKD_UDPPORT=32769' >> /etc/sysconfig/nfs
echo 'MOUNTD_PORT=892' >> /etc/sysconfig/nfs
echo 'RQUOTAD_PORT=875' >> /etc/sysconfig/nfs
echo 'STATD_PORT=662' >> /etc/sysconfig/nfs
echo 'STATD_OUTGOING_PORT=2020' >> /etc/sysconfig/nfs
#
iptables-save > /etc/sysconfig/iptables
# note that on a single-bare-metal-host deployment these rules are incomplete!
# a single-host setup also requires client nfs mount points, especially for the secondary storage
# which is where VM templates are stored ... se we need -A OUTPUT rules here too ...
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p udp --dport 111 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p tcp --dport 111 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p tcp --dport 2049 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p tcp --dport 32803 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p udp --dport 32769 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p tcp --dport 892 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p udp --dport 892 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p tcp --dport 875 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p udp --dport 875 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p tcp --dport 662 -j ACCEPT' >> /etc/sysconfig/iptables
echo '-A INPUT -s 10.101.8.0/24 -m state --state NEW -p udp --dport 662 -j ACCEPT' >> /etc/sysconfig/iptables
# need to manually edit iptables file
# this works (from http://stackoverflow.com/questions/26187345/iptables-rules-for-nfs-server-and-nfs-client):
# NFS server input
-A INPUT -s 10.101.8.0/24 -d 10.101.8.0/24 -p udp -m multiport --dports 10053,111,2049,32769,875,892 -m state --state NEW,ESTABLISHED -j ACCEPT
-A INPUT -s 10.101.8.0/24 -d 10.101.8.0/24 -p tcp -m multiport --dports 10053,111,2049,32803,875,892 -m state --state NEW,ESTABLISHED -j ACCEPT
#
# NFS client input
-A INPUT -s 10.101.8.0/24 -d 10.101.8.0/24 -p udp -m multiport --sports 10053,111,2049,32769,875,892 -m state --state ESTABLISHED -j ACCEPT
-A INPUT -s 10.101.8.0/24 -d 10.101.8.0/24 -p tcp -m multiport --sports 10053,111,2049,32803,875,892 -m state --state ESTABLISHED -j ACCEPT
# and
# server output
-A OUTPUT -s 10.101.8.0/24 -d 10.101.8.0/24 -p udp -m multiport --sports 10053,111,2049,32769,875,892 -m state --state ESTABLISHED -j ACCEPT
-A OUTPUT -s 10.101.8.0/24 -d 10.101.8.0/24 -p tcp -m multiport --sports 10053,111,2049,32803,875,892 -m state --state ESTABLISHED -j ACCEPT
#
# client output
-A OUTPUT -s 10.101.8.0/24 -d 10.101.8.0/24 -p udp -m multiport --dports 10053,111,2049,32769,875,892 -m state --state NEW,ESTABLISHED -j ACCEPT
-A OUTPUT -s 10.101.8.0/24 -d 10.101.8.0/24 -p tcp -m multiport --dports 10053,111,2049,32803,875,892 -m state --state NEW,ESTABLISHED -j ACCEPT
#
service iptables restart
#
service rpcbind start
service nfs start
chkconfig rpcbind on
chkconfig nfs on
exportfs -av
# cloudstack-installation doc indicates /mnt/secondary is required for KVM libvirtd
mount -t nfs c8-14.icbr.local:/export/secondary /mnt/secondary
#
# mysql
touch /etc/my.cnf
echo '[mysqld]' >> /etc/my.cnf
echo 'innodb_rollback_on_timeout=1' >> /etc/my.cnf
echo 'innodb_lock_wait_timeout=600' >> /etc/my.cnf
echo 'max_connections=350' >> /etc/my.cnf
echo 'log-bin=mysql-bin' >> /etc/my.cnf
echo "binlog-format = 'ROW'" >> /etc/my.cnf
mysql_install_db --user=mysql --ldata=/var/lib/mysql
service mysqld start
chkconfig mysqld on
#
# Run the following command to secure your installation. You can answer “Y” to all questions.
mysql_secure_installation # set root password to "cloud" ... see below
#
# use downloaded RPMs:
#rpm -i RPMs/cos6cloudstack-common-4.8.0-1.el6.x86_64.rpm
#rpm -i RPMs/cos6cloudstack-management-4.8.0-1.el6.x86_64.rpm
#
# use yum
yum install -y cloudstack-common
yum install -y cloudstack-management && chkconfig cloudstack-management off

# management rpm indicates:
# Please download vhd-util from http://download.cloud.com.s3.amazonaws.com/tools/vhd-util and put it in
# /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/
pushd /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver
curl -O http://download.cloud.com.s3.amazonaws.com/tools/vhd-util
chmod a+rx vhd-util
#
# note this overwrites any existing /etc/cloudstack/management/db.properties
# make sure these are congruent:
# /etc/cloudstack/management/db.properties ; /usr/share/cloudstack-management/conf/db.properties
cloudstack-setup-databases cloud:@localhost --deploy-as=root:cloud
#
# double check that mysql db is up and user cloud and root exist. note that db.properties file
# indicates 'cloud' is the exected password (used by tomcat webapp)
# if below fails with 'cloud' password, follow instructions in https://redmine.biotech.ufl.edu/projects/day-to-day/wiki/Cloud_MySQL
# mysql -u cloud -p
 
#
# If you are running the KVM hypervisor on the same machine with the Management Server, edit /etc/sudoers and add the following line:
# Defaults:cloud !requiretty
# Now that the database is set up, you can finish configuring the OS for the Management Server.
# This command will set up iptables, sudoers, and start the Management Server.
# cloudstack-management rpm install also indicates:
# Unable to determine ssl settings for server.xml, please run cloudstack-setup-management manually
# Unable to determine ssl settings for tomcat.conf, please run cloudstack-setup-management manually
cloudstack-setup-management
#
#rpm -i RPMs/cos6cloudstack-agent-4.8.0-1.el6.x86_64.rpm
#cos6cloudstack-baremetal-agent-4.8.0-1.el6.x86_64.rpm
#rpm -i RPMs/cos6cloudstack-cli-4.8.0-1.el6.x86_64.rpm
#rpm -i RPMs/cos6cloudstack-usage-4.8.0-1.el6.x86_64.rpm
#
# use yum
yum install cloudstack-agent && chkconfig cloudstack-agentoff
yum install cloudstack-cli
#
# CLI is python ... (not sure if this can be installed before cli rpm?)
pip install cloudmonkey apache-libcloud
#
touch /etc/libvirt/qemu.conf
echo 'vnc_listen=0.0.0.0' >> /etc/libvirt/qemu.conf
#
touch /etc/libvirt/libvirtd.conf
echo 'listen_tls = 0' >> /etc/libvirt/libvirtd.conf
echo 'listen_tcp = 1' >> /etc/libvirt/libvirtd.conf
echo 'tcp_port = "16059"' >> /etc/libvirt/libvirtd.conf
echo 'auth_tcp = "none"' >> /etc/libvirt/libvirtd.conf
echo 'mdns_adv = 0' >> /etc/libvirt/libvirtd.conf
#
touch /etc/sysconfig/libvirtd
echo 'LIBVIRTD_CONFIG=/etc/libvirt/libvirtd.conf' >> /etc/sysconfig/libvirtd
echo 'LIBVIRTD_ARGS="--listen"' >> /etc/sysconfig/libvirtd
service libvirtd restart
#
# Secondary storage must be seeded with a template that is used for CloudStack system VMs.
# from: http://www.shapeblue.com/virtualbox-test-env/ -- note that our nfs exports is /mnt/{primary,secondary}
#
# note 4.6 below -- 4.8 does not exist (tried but failed) ... should montior 4.8 install doc for any change?
# Xenserver
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.6/systemvm64template-4.6.0-xen.vhd.bz2 -h xenserver -F
# KVM hypervisor
#/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.6/systemvm64template-4.6.0-kvm.qcow2.bz2 -h kvm -F
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u https://packages.shapeblue.com/systemvmtemplate/custom/bigvarlog/systemvm64template-bigvarlog-16-kvm.qcow2.bz2 -h kvm -F
# LXC:
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.6/systemvm64template-4.6.0-kvm.qcow2.bz2 -h lxc -F
#
echo check port 8080 for tomcat ...
#
# to see a fresh set of logs:
service cloudstack-management stop
service cloudstack-usage stop
service cloudstack-management stop
service cloudstack-usage stop
#service cloudstack-agent stop
#service cloudstack-ipallocator stop
mv /var/log/cloudstack /var/log/.cloudstack
#mkdir -p /var/log/cloudstack/{management,usage} ; chown -R root:cloud /var/log/cloudstack ; chmod -R ug+rwx /var/log/cloudstack
service cloudstack-management stop
service cloudstack-usage stop
#
# log in to http://192.168.33.10:8080/client with username admin and password password.
#
# choose "Continue with basic installation". This will start a wizard that will walk through the configuration. You will need to adjust the network values for your environment, and make sure you use appropiate, free, ranges.
#
# add a new zone named "ICBR", DNS1 192.168.33.1 and Internal DNS 192.168.33.1
#
# add a new pod named "aPod", gateway 192.168.33.1, netmask 255.255.255.0, IP range 192.168.33.100 - 192.168.33.109 (management)
# add a guest network, gateway 192.168.33.1, netmask 255.255.255.0, IP range 192.168.33.110 - 192.168.33.199 (users)
# add a cluster named cluster1, Hypervisor XenServer or KVM
# add a host. Host Name "CloudstackEval" or IP 192.168.33.10, user root, password for the root linux user.
# add primary storage: name primary, protocol NFS, Scope Cluster, server 192.168.33.10, path /mnt/primary.
# add secondary storage: name secondary,  NFS server 192.168.33.10, path /mnt/secondary.
# hit Launch and pray ... this should go through a sequence of setup steps ..
