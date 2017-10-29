CREATE USER 'hon'@'localhost' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE keystone;
CREATE DATABASE keystone;
CREATE USER 'keystone'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE glance;
CREATE DATABASE glance;
CREATE USER 'glance'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE cinder;
CREATE DATABASE cinder;
CREATE USER 'cinder'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE heat;
CREATE DATABASE heat;
CREATE USER 'heat'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE magnum;
CREATE DATABASE magnum;
CREATE USER 'magnum'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON magnum.* TO 'magnum'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON magnum.* TO 'magnum'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE neutron;
CREATE DATABASE neutron;
CREATE USER 'neutron'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE nova;
CREATE DATABASE nova;
CREATE USER 'nova'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE nova_api;
CREATE DATABASE nova_api;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

DROP DATABASE nova_cell0;
CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON *.* TO 'hon'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON *.* TO 'hon'@'%' IDENTIFIED BY 'cloud';
FLUSH PRIVILEGES;

show databases;

