# Cloudstack

## Evaluation of cloudstack 4.8.0, 4.8.0.1, and 4.9.0 all-in-one deployment(s)
   Each evaluation is performed with a single CentOS 6 host running all services, using the KVM hypervisor.

# Refs.

## At a minimum, follow the official installation-n-config guides; and each doc includes two must-read sections entitled:
     "Quick Installation Guide for CentOS6" and "Host KVM Installation".

## Release 4.9
  http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.9/hypervisor/kvm.html
  and http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.9/qig.html
  and http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.9

## Release 4.8
  http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/hypervisor/kvm.html
  and http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/qig.html
  and http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.8/

  Note the above online docs. (4.8 and 4.9) provide a Search option -- sadly "uuid" or "UUID" yields
  only 1 hit -- http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/4.9/hypervisor/xenserver.html?highlight=uuid
  See the below's agent.properties discussion

## While this is an OpenStack doc. the VLAN and other sections apply to Cloudstack:
  http://docs.openstack.org/mitaka/networking-guide/intro-basic-networking.html#vlans

## And here is more on the Cloudstack VM network subsystem (somewhat corresponding to OpenStack Neutron):
  http://docs.cloudstack.apache.org/projects/cloudstack-administration/en/4.9/networking_and_traffic.html

## Also, this ref is worth a look, although a tad dated:
  https://cwiki.apache.org/confluence/display/CLOUDSTACK/SSVM,+templates,+Secondary+storage+troubleshooting

# A. Preliminaries

1. Decide what LAN setup to use ... bridges with (real and virtual) NICs assigned, (multiple) IPs assigned to bridges, tagged VLAN or not, routing table with default gateway ... The fewer subnets the better (like 10.101.20.0 and 10.13.80.0)

  Note there MUST be a default gateway in the bare-metal host routing table. Once the cloudstack configuration completes successfully,
  do NOT change the default gateway (although we may be able to use a 2-ndary gateway via other/multiple routing tables).

2. Git clone the ICBR repo. day-to-day and take a look at day-to-day/2016/07/{5169,CoudstackAssets} -- lots of (real and pseudo) bash and python scripts and other files.

3. Backup /etc/sysconfig/iptables file.

  Note the ports cloudstack needs: https://cwiki.apache.org/confluence/display/CLOUDSTACK/Ports+used+by+CloudStack
  for Apache Tomcat (HTTPD), NFS, DNS, etc., and also VNC 5800-6100

4. Set SELinux to Permissive: "setenforce 0". Review cs_yum_rpms.sh (do not attempt to run this pseudo bash script), and perform the indicated sets of "yum installs" and "pip installs".

4. After installing all deps, make sure mysqld and NetworkManager are not running:

  * service mysqld stop ; chkconfig mysqld off
  * service NetworkManager stop ; chkconfig NetworkManager off
  And consider yum remove NetworkManager.

5. First install yum/rpm cloudstack-common, then the agent and management servers ... Some deps. may not be available via yum. For 4.9 it was necessary to download the new mysql-connector-python-*.rpm from:

  * https://dev.mysql.com/downloads/connector/python

6. After yum/rpm of cloudstack-management and cloudstack-agent (and/or after running the setup-managment script, see below), check if they are up/running, and if so, stop them:

  * service cloudstack-agent status ; service cloudstack-agent stop ; chkconfig NetworkManager off
  * service cloudstack-management status ; service cloudstack-management stop ; chkconfig cloudstack-management off

7. yum/rpm cloudstack-cli and use python-pip for cloud(stack) modules: pip install cloudmonkey apache-libcloud

8. Backup the newly created directories (by the yum/rpm) /usr/share/cloudstack-common/vms and /etc/cloudstack/{agent,management}

  * /etc/cloudstack/agent/agent.properties -- must be hand-edited and backed-up; agent service (re)start will overwrite it
  * /etc/cloudstack/management/db.properties -- can be hand-edited (or use init_db bash func -- see below)
  * The ISO for all System VMs results in running instances must be "patched" after 1st-time boot-up.

      4.8: -rw-------. 1 root  root  70M Jul 14 15:02 /usr/share/cloudstack-common/vms/systemvm.iso -- be sure to backup a copy.
           -rw-rw-rw-. 1 cloud cloud 69M Jan 30  2016 /usr/share/cloudstack-common/vms/systemvm.zip

      4.9: -rw-rw-rw-. 1 cloud cloud 76M Aug  2 03:40 /usr/share/cloudstack-common/vms/systemvm.iso -- seems intact after many restarts

9. Start the mysqld and source cs_mysql.sh: ". ./bash/cs_mysql.sh"

10. The yum/rpm management post-install indicates one should manually run: /usr/bin/cloudstack-setup-management

  * The above script creates and inits the mysql "cloud" db and db-account, and overwrites /etc/cloudstack/management/db.properties
  * The above also inserts some cloudstack iptables rules and performs iptables-save, overwriting /etc/sysconfig/iptables

11. The newly created iptables file lacks all annotations/comments; these should be merged into the new file from the backup.

12. Our cs_mysql.sh bash script defines some convenient bash functions, run: init_db

13. init_db ensures there is a mysql cloud db-account, and /etc/cloudstack/management/db.properties contains the proper db-account and passwords

14. There is no equiv. agent setup script for /etc/cloudstack/agent/agent.properties; this must be hand edited

  * Create 2 uuids: uuidgen && uuidgen ... samples below ...

    + 88bf4f6f-b542-4d71-b733-e1e0bc28542c
    + d2197860-f163-402e-8553-cce792a9cd39

  * Cut-n-paste uuids into /etc/cloudstack/agent/agent.properties (specifically):

    + guid=88bf4f6f-b542-4d71-b733-e1e0bc28542c
    + local.storage.uuid=d2197860-f163-402e-8553-cce792a9cd39

  * Note the agent.properties file contains zone, pod, and cluster names each set to "default". If these are left as-is/unedited, one MUST specify "default" as the name for the zone, pod, and cluster setup with the Admin GUI (see below).
   Also be sure to double-check there are no typos in the zone, pod, and cluster names. The names that are present in
   the agent.properties files MUST be CONGRUENT with the names entered in the Admin GUI dialogues.

  * The simplest edit of the agent.properties file would be just the 2 uuids. This would induce the agent to look at the host network config for NICs (but it ignores bridges). It does not create bridges, expecting to find "cloudbr0" and optionally "cloudbr1". But it will create 3 or 4 vNICs for each system VM and vNIC for each guest VM which it attaches to the bridge(s).
  Even when one edits the agent.properties, the agent proceeds with "cloudbr0" and possibly "cloudbr1". For our single host setup a single bridge suffices, so consider editing all bridge entries in agent.properties to == cloudbr0.

  * Another edit to consider in agent.properties is the "use local storage", ensuring that guest VM image files are placed in the standard location /var/lib/libvirt/images.

# B. Other system config. /etc... /mnt... (the latter for NFS, not external drives) files for cloudstack

## The Quick Installation Guide (see URL refs. above) indicates these minimal edits:

1. edit /etc/exports to provide 2 NFS mounts ( and mkdir /mnt/{primary,secondary} ):

  * grep -v \# /etc/exports
    /                  *(rw,fsid=0)
    /export            *(rw,nohide,sync,no_root_squash,no_subtree_check)
    /export/primary    *(rw,nohide,sync,insecure,no_subtree_check)
    /export/secondary  *(rw,nohide,sync,insecure,no_subtree_check)
  * mount -t nfs4 hostIP:/export/secondary /mnt/secondary ; mount -t nfs4 hostIP:/export/primary /mnt/primary

2. edit /etc/libvirt/qemu.conf:
    grep 'vnc_listen' /etc/libvirt/qemu.conf
    vnc_listen="0.0.0.0"

3.  edit /etc/libvirt/libvirtd.conf:
    egrep 'listen|tcp|mdns' /etc/libvirt/libvirtd.conf | grep -v \#
    listen_tls=0
    listen_tcp=1
    tcp_port="16509"
    mdns_adv = 0
    auth_tcp="none"

4. edit /etc/sysconfig/libvirtd:
    grep LIBVIRTD /etc/sysconfig/libvirtd | grep -v \#
    LIBVIRTD_ARGS="--listen"

    Once the above edits are completed: service libvirtd restart.

## It is IMPORTANT to note the host KVM installation indicates the NFS /mnt/secondary MUST be remain mounted at all times. Also it is IMPLIED that /mnt/secondary is a MANDATORY mount point (not /net/secondary or whatever), despite the admin GUI dialogue that prompts the user to enter whatever. So be sure to enter this mount point name without typos in the Admin GUI dialogue.

  It is also IMPORTANT to note that whether the management service and hypervisor agent service are running on
  the same host or different hosts on the LAN, the system install-n-config has fewer glitches/gotchas if one
  places all network elements on the same subnet (ICBD 10.101.20.0/24 should be ideal). There have been innumerable
  issues with the eval. using 3 subnets -- 10.13.80.0, 10.101.8.0, and 172.0.0.0 ... Also, it is better/cleaner
  to assign IPs to bridges rather than NIC eth*s.

  The KVM hypervisor docs. indicated above provide a specific detailed example of a tagged VLAN eth0.100-300
  3 (virtual) NICs and 2 bridges (cloudbr0 and cloudbr1) network config. using ifconfig (vconfig, and brctl
  commands provide diagnostics and non-persistent config. options).

  Our two evaluation hosts (c8-13 and c8-14) /etc/sysconfig/network-scripts/ifcfg* are slightly different
  simplifications of the KVM doc. example which primarily use cloudbr0 (cloudbr0-1 seem to be hardcoded in
  some cloudstack code).

  The c8-13 network is actually not setup with the tagged VLAN 100-300, it uses cloudbr0 with multiple
  IPs configured vi the iproute2-tools (not ifconfig-net-tools; see /etc/rc.local):

    ip addr add 172.16.10.2/24 brd + dev cloudbr0

  The c8-14 network config. uses ifconfig scripts /etc/sysconfig/network-scripts/ifcfg-eth0.100,200,300
  as described in the KVM docs., but all are assigned to the cloudbr0 bridge.

1. Some host system configs. and /etc file edits that seem to improve the odds of success:

  * Rebooting with the Secondary Storage VM up-n-running can hang NFS, due to mounts being "busy", and
    starting NFS at host boot can also be problematic (especially if /etc/fstab indicates NFS mounts).
    Consequently it is safer to disable many of the cloudstack service deps. After a clean reboot:
    <pre>
    chkconfig --list|egrep -i 'aud|cloud|iptab|virt|dnsm|mysq|network|nscd|ntp|nfs|bind|tomc'
      auditd                  0:off	1:off	2:on	3:on	4:on	5:on	6:off
      cloudstack-agent        0:off	1:off	2:off	3:off	4:off	5:off	6:off
      cloudstack-ipallocator  0:off	1:off	2:off	3:off	4:off	5:off	6:off
      cloudstack-management   0:off	1:off	2:off	3:off	4:off	5:off	6:off
      dnsmasq                 0:off	1:off	2:off	3:off	4:off	5:off	6:off
      iptables                0:off	1:off	2:on	3:on	4:on	5:on	6:off
      libvirt-guests          0:off	1:off	2:on	3:on	4:on	5:on	6:off
      libvirtd                0:off	1:off	2:on	3:on	4:on	5:on	6:off
      mysqld                  0:off	1:off	2:off	3:off	4:off	5:off	6:off
      network                 0:off	1:off	2:on	3:on	4:on	5:on	6:off
      nfs                     0:off	1:off	2:off	3:off	4:off	5:off	6:off
      nfslock                 0:off	1:off	2:off	3:off	4:off	5:off	6:off
      nscd                    0:off	1:off	2:off	3:off	4:off	5:off	6:off
      ntpd                    0:off	1:off	2:on	3:on	4:on	5:on	6:off
      ntpdate                 0:off	1:off	2:off	3:off	4:off	5:off	6:off
      rpcbind                 0:off	1:off	2:off	3:off	4:off	5:off	6:off
      virt-who                0:off	1:off	2:on	3:on	4:on	5:on	6:off
   </pre>

    The above hopefully ensured a fast / simple boot-up. One must then manually
    "service name start" of the items listed above that indicate "off".
    Notice that libvirtd should be up immediately after reboot, but any subsequent
    edit of /etc/libvirt* conf. files will require a restart. It's worth
    checking the default libvirtd (KVM) boot status:

    + virsh list ; virsh net-list ; virsh pool-list

      The 1st list should show any running VMs.

      There should be a "default" network and but no running VMs, unless
      somehow the cloudstack services were started on boot.

    If there are pools, check if the pools have volumes:

    + virsh vol-list any-pool-Id-shown

    Below there are some check-list items for using virsh to flush / remove any
    lingering cloudstack remnants, if desired (see the section on forcing the
    hypervisor agent to create new system VMs).

  * Before a reboot, double check /etc/rc.local:

    + c8-13:/etc/rc.local -- ip addr add 172.16.10.2/24 brd + dev cloudbr0
    + c8-14:/etc/rc.local -- ?

  * After a reboot, check the route table and network config (route -n, ifconfig, etc.). We need to decide if the default boot-up should enable the public / campus VLAN 989 tag.

    But there must be a default gateway in the route table, otherwise the the cloudstack-management service will fail
    to startup (with very obscure error logs). Once the cloudstack system has been configured with a specific default
    gateway in the route table, changing the default gateway seems to cause problems for cloudstack-management.

  * Various and sundry files under /etc that have been touched during the cloudstack eval (attempting to configure as sudoer rather than root):

    + /etc/audit\* -- selinux audit rules
    + /etc/init.d/cloudstack\* -- startuo scripts
    + /etc/libvirt\* -- conf user, group, tcp, etc.
    + /etc/{exports,hosts,hosts.allow,idmapd.conf,my.cnf,passwd,shadow,sysctl.conf} -- ipv4 forwarding, NFS, KVM, non-krb5 ssh logins
    + /etc/modprobe.d/ipv6.conf -- comment all lines out (ala Sir Alex)
    + /etc/polkit\* -- libvirt users
    +  /etc/security/\* -- non-krb5 logins
    +  /etc/selinux/config -- permissive vs. enforcing
    +  /etc/ssh/\* -- non-krb5 login
    +  /etc/sysconfig/{ptables,network\*} -- eth0-1, br0-1, cloudbr0-1
    +  /etc/udev/rules.d/\* -- ?
    +  /etc/xinetd.d/\* -- TBD
    +  /etc/yum.repos.d/cloudstack -- yum install

# C. Initial Configuration via Admin GUI

1. Before starting the cloudstack services be sure that:

  * Mysqld, RPCbind, and NFS services are running. NFS exports should include:

    + exportfs -v
    <pre>
      /export           <world>(rw,wdelay,nohide,no_root_squash,no_subtree_check,sec=sys,rw,no_root_squash,no_all_squash)
      /export/primary   <world>(rw,wdelay,nohide,insecure,root_squash,no_subtree_check,sec=sys,rw,root_squash,no_all_squash)
      /export/secondary <world>(rw,wdelay,nohide,insecure,root_squash,no_subtree_check,sec=sys,rw,root_squash,no_all_squash)
    </pre>

  * /mnt/secondary has been seeded with the Qemu-KVM qcow2 guest VM template via:

    + /usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://cloudstack.apt-get.eu/systemvm/4.6/systemvm64template-4.6.0-kvm.qcow2.bz2 -h lxc -F

    Note the above version 4.6.0 seems to be appropriate for the 4.8 and 4.9 cloudstack releases. However,
    the 4.9 admin GUI shows for the Virtual Router System VM: Requires Upgrade "Yes", while the 4.8 GUI shows "No".

  * One has run the unlock.sh script to ensure the cloudstack services have full access to the file-system. this sets selinux
    to permissive and chmod's certain essential items.

  * The route table has been configured with the desired default gateway -- 10.a.b.1 or 10.c.d.1 or 172.16.a.1 or 172.17.b.1 ...

  * The cloudbr0 bridge is up and fully configured with desired management and hypervisor host IP: brtcl show and ifconfig, etc.
    Note the KVM installation guide indicates two cloudstack specific bridges: cloudbr0 and cloudbr1 ... however,
    in a "basic networking" config, only cloudbr0 is needed (simpler and perhaps more efficient)

2. One may wish to edit the log4j XML config. files to increase log-levels to DEBUG or TRACE:

  * /etc/cloudstack/agent/log4j-cloud.xml

  * /etc/cloudstack/management/log4j-cloud.xml

3. Start the management service: service cloudstack-management start && tail -f /var/log/cloudstack/management/management-server.log

4. Navigate one's browser to the management (for a single host setup this is also the hypervisor) host URL -- http://host:8080/client

5. When adding a host to a cluster, the Admin GUI prompts for an account and password with the hint "Usually root".

  All attempts to use a sudoer account rather than root caused problems down-stream. Consequently the only successful
  configs have occurred when using root. Note that the setup script mentioned above creates a so-called
  "password-locked" account "cloud" with group "cloud" that is a sudoer account. It may be of interest to give the 
  cloud account a password and try using it for adding a host to a cluster. Also note that adding a host to a
  cluster requires the cloudstack-agent service to be started and fully initialized and communicating with both
  the management service and libvirtd. If one has restarted the management service after editing the Global Settings
  (see below), with the hypervisor agent up, the agent will usually reconnect gracefully. If the agent is not up,
  the next time one attempts to use the management service Admin GUI to add a host to a cluster, the management server
  may attempt to start the agent (assuming it is configured to run on the same host), but that can take awhile, and
  it's quicker to manually start the agent once the "heartbeats" appear in the management server log.

6. Check the /var/log/cloudstack/agent/agent.log -- it it does not exist or is empty, one may start the agent manually:

  * service cloudstack-agent start && tail -f /var/log/cloudstack/agent/agent.log

7. Global Settings are IMPORTANT -- navigate to the left-side-bar of the Admin GUI and click "Global Settings" (directly under "Infrastructure").

  A very large (but searchable) table of configuration items is presented. Many of these items must be manually set
  after the initial management serivce startup, before starting the hypervisor agent service. In most cases, (re)setting
  a Global Settings item requires a restart (or stop-then-start) of the management-server.
  
  * List of essential settings.

    + CIDRs -- management server network, control network, guest VM

    + Host -- management server host IP ... things are better behaved when this is on the same subnet as the system VMs.

    + Hypervisor.list -- just KVM

    + Secstorage.allowed... -- IMPORTANT "Comma separated list of cidrs internal to the datacenter that can host template     download servers". If not properly set, the secondary storage VM will fail.

    + System.vm.use.localstorage -- true

    + System.vm.default.hypervisor -- KVM

    + \*.rpfilter -- when all cloudstack services run on same/single host may help to set these to 0 (false)

    + ???

8. In general any Global Settings change requires a restart of cloudstack-management.

  * 4.8 seldom stops on the first try, but usually on the 2nd; and before starting it, be sure to restore /usr/share/cloudstack-common/vms/systemvmiso from its (correct) backup.

  * 4.9 restarts are much better behaved, but it is better to perform a stop then a start than a restart.

    + the proper default gateway is setup in the main route table
    + /var/log/cloudstack permissions are open
    + /root/.ssh/*rsa* permissions are open
    + /etc/cloudstack/{agent,management} properties and xml files are correct
    + /usr/share/cloudstack-common/vms/systemvm.iso is intact (4.8: ~69M or 4.9: ~76M, restore from backup if needed)
    + /mnt/{secodary,primary} are mounted rw.

   The unlock.sh script helps with the above and also a number selinux items.

# D. System VM Patches and Early-Config -- once the admin GUI "Infrastructure" shows 2 System VMs

1. Patching 4.9 vs. 4.8

  * 4.9: /usr/share/cloudstack-common/scripts/vm/hypervisor/kvm/patchviasocket.py and

  -rw-rw-rw-. 1 cloud cloud 76M Aug  2 03:40 /usr/share/cloudstack-common/vms/systemvm.iso
  The 4.9 ISO contains a full /usr/local/cloud/systemvm directory, with all *.jar *.py, *.sh deps.
  But ssh key-pairs may not have been inserted properly ... virsh console works, ssh and scp may not ...
  One can virsh console into each running system VM (root password) and manually configure sshd,
  and cut-n-paste the RSA key into /root/.ssh/*rsa*.

  * 4.8: this ISO is smaller and its /usr/local/cloud/systemvm is nearly empty:

  -rw-------. 1 root  root  70M Jul 14 15:02 /usr/share/cloudstack-common/vms/systemvm.iso
  -rw-rw-rw-. 1 cloud cloud 69M Jan 30  2016 /usr/share/cloudstack-common/vms/systemvm.zip

  Virsh console usually will not work (in 4.8) until the system VMs are more fully patched.
  Fortunately ssh via -p 3922 and scp -P 3922 to the system VM's link-local eth0 (169.254.x.y) work.

  scp /usr/share/cloudstack-common/vms/systemvm.zip into each system VM (/var/tmp) and then
  ssh login and unzip into either /usr/local/cloud/systemvm or /opt/cloud/systemvm and sym-link
  one to the other. Then run: service cloud-early-config (re)start and service (re)start and
  check /var/log/cloud.log for any errors, etc.

  Once /usr/local/cloud/systemvm/* files are installed, (re)run / (re)start the cloud services:

  * service cloud-early-config restart -- this may cause a reboot of the VM
  * service cloud restart -- check /var/log/cloud.log for errors, exceptios, etc:
    egrep -i 'abor|canno|erro|excep|fail|fata|unable' /var/log/cloud.log

2. Once the system VMs have been patched, try rebooting each via the admin GUI. The GUI needs to be refreshed manually to observe changes in state/status of the system VMs.

3. Once the System VMs are fully booted, try to virsh console into each.

  Virsh list should show VM names s-*-VM for the secondary-storage VM, v-*-VM for the console-proxy VM, r-*-VM for
  any virtual-router VM, and i-*-VM for any guest VMs. The virtual router VM (r-*-VM) does not
  appear to be created and booted by the system until one attempts to launch a guest VM.

4. Note the system VMs are Debian 7 (wheezy) and are running sshd and iptables. It may be necessary to modify /etc/ssh/sshd_conf and /etc/iptables/rules.v4 then restart each:

  * service ssh restart
  * service iptables-persistent restart

5. Each fully patched system VM should have a verification test script one can run:

  /usr/local/cloud/systemvm/ssvm-check.sh

  In order for the ssvm-check script to work fully, however, the VM needs access to the Internet.
  The network config. across the host and the system VMs needs to be setup to allow access to the
  Internet -- the UF campus bridge br1 and VLAN tag eth1.989 are up , and the VMs can route across
  cloudbr0 (thru br0?) thru br1 to the Internet. During the "early-config" and subsequent post-install
  config., and then using guest VMs, it is possible to achieve considerable functionality without
  Internet access. Nevertheless, it is highly desirable to provide some level of Internet access from
  our private cloud.

6. In the event our manual patch effort or some other activity has damaged a system VM beyond repair, one can force the hypervisor agent to create new system VMs.

  Navigate to the "Infrastructure" page of the Admin GUI and select System VMs. Click on the (damaged) VM
  and select the option to place it into "maintenance mode". If that succeeds, select the option to
  destroy and expunge it. Whether or not this succeeds, it may still be necessary to use virsh.
  As root shutdown the cloudstack services and invoke virsh:

  * service cloudstack-agent stop ; service cloudstack-management stop

  * virsh list -- note VM names, if any are shown and try:
    virsh shutdown each-VM-name -- or destroy or undefine

  * virsh pool-list -- and note any/all the pool Ids

  * virsh vol-list each-pool-name -- note all the vol-names

  * for each vol of each pool: virsh vol-delete vol-name pool-name

  * for each pool-name: virsh pool-delete pool-name

  Optionally copy/backup the current log files and then "truncate -s 0" all logs and restart the services:

    service cloudstack-management start

  Monitor the management-server.log for awhile to see the "heartbeats":

    grep -i heartbeat /var/log/cloudstack/management/management-server.log|tail -2
    2016-08-18 17:53:47,377 INFO  [o.a.c.f.j.i.AsyncJobManagerImpl] (AsyncJobMgr-Heartbeat-1:ctx-49311184) (logid:a4ca6d21) Begin cleanup expired async-jobs
    2016-08-18 17:53:47,381 INFO  [o.a.c.f.j.i.AsyncJobManagerImpl] (AsyncJobMgr-Heartbeat-1:ctx-49311184) (logid:a4ca6d21) End cleanup expired async-jobs

  After a few minutes, if the above grep fails to find any heartbeats, we have a problem. But if we see heatbeats, then
  refresh (re-login) to eh Admin GUI and proceed with the agent restart:

  * service cloudstack-agent start -- and after many many minutes Admin GUI Infrastructure will show 2 (new) System VMs
  * Click thru to the System VM page and monitor their status by refreshing the page. Eventually thet status should change to green "Running".

      Note their names and IPs.

  * Try to virsh console into each VM-name, or ssh -P 3922 into each VM's link-local IP.
  * If one can login as root (password), check the contents of each VM's /usr/local/cloud/systemvm

# E. Registration of Templates (qcow2 images) and ISOs.

1. Start a http web-server on the host that provides file downloads via URLs.

2. Navigate to the Admin UI left-side-bar and to the Templates page.

3. The Template pull-down allows one to either upload a template or specify a URL, but the upload will not work from our iMAC desktops due to the CIDR network config. A URL of the management host will work if we have an http web-server running on the host (and proper Global Settings).

4. The ISO registration only supports URLs, again we need a http web-server up on the host.

5. Make sure to select/enable "Featured" and "Shared" in the registration dialogue.

  The GUI will blink for a short while then a pop-up appears indicating success (or not). But the success indicated is premature.
  It actually takes considerably longer for the system to make the new offering available.
  Click thru "Add Instance" and "Template" or "ISO" and "Featured" a few times and eventually the new item will be shown in the list.
  Sometimes a new item can appear in a tab then be removed later by the system for mysterious reasons (some I/O issure or perhaps SELinux)?

# F. Launch and Use a Guest VM

1. Navigate to the Admin or User GUI left-side-bar and click "Instances", then click "Add Instance".

2. A page is presented that allows one to navigate / choose "Featured" or "Community" or "Shared" Templates or ISOs from their respective lists.

3. Once the new (featured) ISO or Template is selected, proceed with the subsequent steps and launch.
   There are 8 steps to the "Add Instance" action:

  * Setup -- zone and ISO or Template buttons
  * Select -- specific ISO or Template (qcow2 image for KVM hypervisor) from "Featured" or other tab.
  * Compute Offering -- small or medium (RAM, CPUs, etc.)
  * Disk Offering == small, medium, large, custom, etc.
  * Affinity -- no affinity groups are defined when there is only 1 hypervisor host on 1 cluster (our only possible affinity).
  * Network -- in "basic networking" config there is only 1 network choice ("default")
  * SSH KeyPair -- none; each guest VM should ultimately establish unique pairs per user.
  * Review and Launch -- provide an optional name for the instance.

4. Navigate back to the GUI "Instances" page and refresh it a few time to observer the table of instances update and eventually show its dynamically allocated IP address and its "State" become green "Running".

5. Click on the instance name shown in the table to navigate to a page that present 4 tabs.

6. The named instance page tab "Details" provides a scrollable list that shows VM info. The "NICs" tab shows the guest VM's network config: IP, netmask, default gateway, etc. There is also a "Security Groups" and "Statistics" tab, etc.

7. Once the guest VM is fully booted, navigate to the "Instances" page in the User or Admin GUI and click into the instance "Details" tab.
Note the row of small icons shows (the rightmost) one that looks like ">_". Hover the mouse over the icon and a pop-up label should appear:

  * "View console". To access the guest VM, click on the icon and a new browser window should appear
    and indicate it is attempting to connect to the guest VM via the Console Proxy system VM IP.
    If the browser app. is running on the hypervisor host. or some other host that has unrestricted
    network access to the VMs, the window should display the VM's OS console. If the guest VM derives
    from a "live" ISO, the console will likely be a Desktop GUI. If the guest VM derives from an install
    ISO, the console should display a typical install (text or GUI) prompt.

  * If the only network route to the guest VM is the hypervisor host, viewing the VM console via the
    cloudstack wep-app User or Admin browser interface requires running the browser directly on the
    hypervisor bare-metal OS, via X11 forwarding. Consequently some X11 (client) deps. must be installed,
    and the sshd config. must support the forwarding. An X11 client package install (yum/rpm) may result
    in NetworManager being installed and started. The NetworkMager service may interfere with the network
    config that has been manually created. It seems best to disable NetworkManager, and remove it altogether.

  * Note there is known bug in the cloudstack console poxy, as described here:

    https://issues.apache.org/jira/browse/CLOUDSTACK-9164

    The above describes a manual patch for the console's "ajaxviewer.js" that should be found in the VM's
    /usr/local/cloud/systemvm/js sub-directory.

    Copy (scp) the patchfile (prevent_quick_search_key.patch) to the hypervisor host from the git cloned
    directory that also contains this cs_checklist.txt. Then on the hypervisor copy (scp -P 3922) the
    patchfile to the Console Proxy System VM: /usr/local/cloud/systemvm/js. Then ssh or virsh console to
    the VM and pushd there to perform the patch:

    + cp -p ajaxviewer.js ajaxviewer.js.orig
    + patch < prevent_quick_search_key.patch
    + diff ajaxviewer.js ajaxviewer.js.orig

    Presumably closing and re-opening the Console Proxy browser window will load the new version, but if not,
    clear the browser internal cache and retry.

8. Once launched, the VM life-cycle is somewhat independent of the cloudstack services.

  Stopping the hypervisor agent and/or the managment server does not stop the VMs. VMs can be be shutdown or
  rebootedor destroyed and expunged from the GUI, and as mentioned above if necessary via virsh commands. Note
  that libvirtd dynamically inserts new VM routing rules in iptables, but doe not persist the rules to /etc.
  If one restarts iptables with the VMs still running, but without first saving/persisting their iptable
  entries, connectivity may be lost. Rebooting the VMs should induce libvirtd to (re)create the iptable rules
  for the (NAT and masquerade, etc). But it is recommended to manually persisit the iptables rules after
  each new VM is launched, ensuring iptables restarts yield consistent outcomes.
