GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'cloud';

CREATE USER 'hon'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON *.* TO 'hon'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON *.* TO 'hon'@'%' IDENTIFIED BY 'cloud';

CREATE USER 'keystone'@'localhost' IDENTIFIED BY 'cloud';
# DROP DATABASE keystone;
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'cloud';

CREATE USER 'glance'@'localhost' IDENTIFIED BY 'cloud';
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'cloud';

CREATE USER 'cinder'@'localhost' IDENTIFIED BY 'cloud';
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'cloud';

CREATE USER 'neutron'@'localhost' IDENTIFIED BY 'cloud';
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'cloud';

CREATE USER 'nova'@'localhost' IDENTIFIED BY 'cloud';
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'cloud';

CREATE DATABASE nova_api;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'cloud';

CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'cloud';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'cloud';

FLUSH PRIVILEGES;

show databases;


