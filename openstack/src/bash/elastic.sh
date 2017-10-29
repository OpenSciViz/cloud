#!/bin/sh
# https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html

# no 'latest' tag ... must indicate version number?
# docker pull docker.elastic.co/elasticsearch/elasticsearch:5.5.1

# restart whenenver docker daemon is (re)started
docker ps -a
docker ps |grep elastic
if [ ? != 0 ] ; then
  docker run -dit --name=elastic551 --restart=unless-stopped  -p 9200:9200 -e "http.host=0.0.0.0" -e "transport.host=127.0.0.1" docker.elastic.co/elasticsearch/elasticsearch:5.5.1
  docker ps -a
fi

echo The vm_max_map_count kernel setting needs to be set to at least 262144 for production use. Depending on your platform:
echo The vm_map_max_count setting should be set permanently in /etc/sysctl.conf:

grep vm.max_map_count /etc/sysctl.conf
echo To apply the setting on a live system type: sysctl -w vm.max_map_count=262144

echo test elasticsearch service is alive ...

curl -u elastic:changeme 'localhost:9200/_cat/master?v'
curl -u elastic:changeme 'localhost:9200/_cat/health?v'
curl -u elastic:changeme 'localhost:9200/_cat/indices?format=json&pretty'

