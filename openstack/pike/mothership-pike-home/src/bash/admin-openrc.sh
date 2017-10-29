#!/bin/sh
invoke=$_
string="$0"

subshell=${string//[-._]/}
# echo "subshell == $subshell"

if [ "$subshell" != "bash" ]; then
  echo "$invoke" must be sourced
  echo try: \"'. '${invoke}\" ... or: \"source ${invoke}\"
  exit
fi

export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=oct2017cloud
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

env|grep OS_

