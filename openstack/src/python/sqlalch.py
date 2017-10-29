#!/usr/bin/env python

"""
https://stackoverflow.com/questions/10770377/howto-create-db-mysql-with-sqlalchemy
"""

from sqlalchemy import create_engine

def dbinfo(usr='root'):
  pwd = 'cloud'
  host = 'controller' # '172.17.2.1' # 'localhost'
  #host = 'localhost'
  port = '3306'

  # This engine just used to query for list of databases
  dbroot = create_engine('mysql://{0}:{1}@{2}:{3}'.format(usr, pwd, host, port))

  dblist = dbroot.execute("SHOW DATABASES;")
  for db in dblist:
    print db

  tblist = dbnova.execute("SHOW TABLES;")
  for tb in tblist:
    print tb
# end dbinfo

usrlist = ['root', 'keystone', 'nova', 'neutron']

for usr in usrlist: 
  dbinfo(usr)
