Oct. yum update of Pike RPMs provided new Nova (and Neutron and more) runtimes ...
Uunfortunately nova-compute breaks due to qemu version dependency:

nova-compute.log:2017-10-05 15:16:41.578 12552 ERROR oslo_service.service InternalError: Nova requires QEMU version 2.1.0 or greater.

So far unable to find a newer qemu RPM. Current installed version is 2.0:

qemu-x86_64 -version
qemu-x86_64 version 2.0.0, Copyright (c) 2003-2008 Fabrice Bellard

So ... compiled from source:
https://www.qemu.org/download/#source
https://wiki.qemu.org/Hosts/Linux

wget https://download.qemu.org/qemu-2.10.1.tar.xz

tar xvJf qemu-2.10.1.tar.xz
pushd qemu-2.10.1

./configure --prefix=/usr

make
make install


