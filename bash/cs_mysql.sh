#!/bin/bash

function dbusers {
  echo dbusers $1 ...
  # assuming db admin password is == cloud, create a few more cloudstack db users:
  mysql --password="cloud" --execute="grant all privileges on *.* to 'cloud'@'localhost' with grant option;"
  mysql --password="cloud" --execute="grant all privileges on *.* to 'cloud'@'%' with grant option;"
  mysql --password="cloud" --execute="create user 'david.hon'@'localhost' identified by 'cloud';"
  mysql --password="cloud" --execute="create user 'david.hon'@'%' identified by 'cloud';"
  mysql --password="cloud" --execute="grant all privileges on *.* to 'david.hon'@'localhost' with grant option;"
  mysql --password="cloud" --execute="grant all privileges on *.* to 'david.hon'@'%' with grant option;"
  mysql --password="cloud" --execute="create user 'cloudstack'@'localhost' identified by 'cloud';"
  mysql --password="cloud" --execute="create user 'cloudstack'@'%' identified by 'cloud';"
  mysql --password="cloud" --execute="grant all privileges on *.* to 'cloudstack'@'localhost' with grant option;"
  mysql --password="cloud" --execute="grant all privileges on *.* to 'cloudstack'@'%' with grant option;"
}

function dbinfo {
  echo dbinfo $1 ...
  mysql --password="cloud" --execute="show databases;"
  mysql --password="cloud" --execute="use cloud; show tables;"
  tables='data_center data_center_details cluster cluster_details' 
  mysqldump --password="cloud" cloud $tables
}

function dump_db {
  echo dump entire db $1 ...
  db='cloud'
  mysqldump --password='cloud' $db | tee /var/tmp/${USER}_${db}.mysql
}

function drop_db {
  echo drop db $1 ...
  db='cloud'
  mysql --password='cloud' --execute="drop database $db;"
}

function dump_globalconfig {
  echo dump globalconfig $1 ...
  table='configuration'
  mysqldump --password='cloud' cloud $table | tee /var/tmp/${USER}_cloud_${table}.mysql
}

function restore_globalconfig {
  echo restore_globalconfig $1 ...
  mysql -u cloud --password='cloud' cloud < /var/tmp/${USER}_cloud_globalconf.mysql
}

function storage {
  # from http://mail-archives.apache.org/mod_mbox/cloudstack-users/201507.mbox/<559E0273.1050604@gmail.com>
  mysql --password="cloud" --execute="use cloud; SELECT * FROM cloud.image_store;"
  # Note the store_id (assume x)
  mysql --password="cloud" --execute="use cloud; SELECT * FROM cloud.template_store_ref;" # where store_id=x;
}

function init_db {
# mysql -e "update mysql.user set password=PASSWORD('cloud') where User='root'; flush privileges;" >& /dev/null
  dt=`date "+%Y.%j.%H.%M.%S"`
  dbprop=/etc/cloudstack/management/db.properties
  backup=/etc/cloudstack/management/db.properties${dt}
  if [ -e $dbprop ] ; then
    cp -p $dbprop $backup
  fi
  echo 'db.cloud.name=cloud'
  echo 'db.cloud.password=cloud'
  /usr/bin/cloudstack-setup-databases cloud:@localhost --deploy-as=root:cloud
  mysql --password='cloud' -e "create user 'cloud'@'localhost' identified by 'cloud';" >& /dev/null
  mysql --password='cloud' -e "create user 'cloud'@'%' identified by 'cloud';" >& /dev/null
  mysql --password='cloud' -e "update mysql.user set password=PASSWORD('cloud') where User='cloud'; flush privileges;" >& /dev/null
  echo 'This overwrites existing version /etc/cloudstack/management/db.properties ... be sure to fix it or restore backup'
  if [ -e $dbprop ] ; then
    cp -p $backup $dbprop 
  fi
}

if [ "$1" != "" ] ; then
  dbusers
fi

dbinfo
