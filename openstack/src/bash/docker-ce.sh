#!/bin/sh

pushd /etc/yum.repos.d
mv epel.repo .epel.repo 
mv epel-testing.repo .epel-testing.repo 
pushd

yum remove docker docker-common docker-selinux docker-engine
yum install -y yum-utils device-mapper-persistent-data lvm2

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum makecache fast

yum install docker-ce

# systemctl start docker
# docker run hello-world
