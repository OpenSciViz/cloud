#!/bin/sh
lvextend -L+4G -r /dev/mapper/os-root
lvextend -L+4G -r /dev/mapper/os-var
lvextend -L+4G -r /dev/mapper/os-usr
lvextend -L+4G -r /dev/mapper/os-usrLocal
#lvextend -L+4G -r /dev/mapper/os-home
#lvreduce -L1G -r /dev/mapper/os-home
