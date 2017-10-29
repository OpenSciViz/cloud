#!/bin/sh
echo VM images can be quite large ... mang GBs and consequently do NOT reside in the SCM repos.
echo Fetch the VM image, presumably qcow2 files from the file share or Globus end-point and place them in the ./VMs directory
echo Verify the trasnfer via checksums
ls -ahlqF ./VMs

######################################################

scmId=$Id$
