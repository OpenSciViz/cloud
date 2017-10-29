$!/bin/sh

echo to create and image with metadata property os_distro:

echo glance image-create --name fedora-21-atomic-3 --visibility public --disk-format qcow2 --property os_distro='fedora-atomic' --container-format bare --file fedora-21-atomic-3.qcow2 --progress
