#!/bin/sh

systemctl stop httpd

echo pushd /usr/share/openstack-dashboard
echo python manage.py compress
echo popd

echo pushd /etc/httpd/conf.d
echo head -5 openstack-dashboard.conf
echo WSGIDaemonProcess dashboard
echo WSGIProcessGroup dashboard
echo WSGIApplicationGroup %{GLOBAL}
echo WSGISocketPrefix run/wsgi

echo make sure WSGIApplicationGroup is set ...

systemctl restart httpd memcached

