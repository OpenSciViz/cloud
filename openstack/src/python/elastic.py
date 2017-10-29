#!/usr/bin/env python
"""
https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html
From above:
X-Pack is preinstalled in this image. The default password for the elastic user is changeme.
X-Pack includes a trial license for 30 days. After that, you can obtain one of the available subscriptions or disable Security.
The Basic license is free and includes the Monitoring extension. 

https://www.elastic.co/guide/en/x-pack/5.5/security-getting-started.html
From above:
The default password for the elastic user is changeme.
Change the passwords of the built in kibana, logstash_system and elastic users:

curl -XPUT -u elastic 'localhost:9200/_xpack/security/user/elastic/_password' -H "Content-Type: application/json" -d '{
  "password" : "elasticpassword"
}'

curl -XPUT -u elastic 'localhost:9200/_xpack/security/user/kibana/_password' -H "Content-Type: application/json" -d '{
  "password" : "kibanapassword"
}'

curl -XPUT -u elastic 'localhost:9200/_xpack/security/user/logstash_system/_password' -H "Content-Type: application/json" -d '{
  "password" : "logstashpassword"
}'
"""

from __future__ import print_function
import os, sys
if sys.version_info.major < 3: import six # allows python3 syntax in python2

import inspect, json, magic, requests, string
# import certifi # for use_ssl=True

from elasticsearch import Elasticsearch

_theIndexName = 'LogIndex'

def connect(elastic='http://localhost:9200'):
  """
  https://tryolabs.com/blog/2015/02/17/python-elasticsearch-first-steps/
  and https://docs.objectrocket.com/elastic_python_examples.html
  connect make sure ES is up and running
  """
  print(__name__, inspect.getdoc(__name__))
  es = None
  try:
    es = Elasticsearch([{'host': 'localhost', 'port': 9200}], http_auth=('elastic', 'changeme'), use_ssl=False)
    print("Connected", es.info())
    # res = requests.get(elastic)
    # print(res.content)
  except Exception as ex:
    print("Error:", ex)

  return es

def indexWWW(es, url='http://swapi.co/api/people/', docIds=[]):
  """
  example index of a website
  """
  print(__name__, inspect.getdoc(__name__))
  print(__name__, inspect.getdoc(__name__))
  # connect to our cluster
  if( not es ):
    es = connect()
  #iterate over swapi people documents and index them
  r = requests.get('http://localhost:9200') 
  i = 1 + len(docIds)
  while r.status_code == 200:
    r = request.get('http://swapi.co/api/people/'+ str(i))
    es.index(index=_theIndexName, doc_type='people', id=i, body=json.loads(r.content))
    i = i+1
    docIds.append(i) ; print(i)

  return len(docIds)

def textFileList(flist=[], path='./'):
  """
  walk the directory tree and find all text files and return the list of all found
  """
  print(__name__, inspect.getdoc(__name__))
  files = None
  for dirpath, dirs, files in os.walk(path, topdown=True, onerror=None, followlinks=True):
    for f in files:
      f = os.path.join(dirpath, f)
      mimetype = magic.from_file(f, mime=True, uncompress=True)
      minetype = string.lower(mimetype)
      if(mimetype == 'text/plain'): flist.append(f)

    for d in dirs:
      cnt = textFileList(flist, d)
  # end os.walk
    
  return len(flist)
# end textFileList 


def indexTest(es, i=1, docIds=[]):
  """
  index a single test string
  """
  print(__name__, inspect.getdoc(__name__))

  logtime = datetime.now()
  i = 1 + len(docIds)

  text = str(i) + '.) single line from a text file or ' + inspect.getdoc(__name__)

  # default behavior is to store all ? but since the file is local, let's just store the meta-data if possible ...
  jsonbody = [ {'timestamp': logtime, 'filename': textfile}, {'content': text, 'store': false} ]
  es.index(index=_theIndexName, doc_type='text/plain', id=i, body=jsonbody)

  docIds.append(i) ; print(i)
  return i

def indexTextFileByLine(es, textfile, docIds=[]):
  """
  read each line of text from file and index each as a single string
  """
  print(__name__, inspect.getdoc(__name__))

  logtime = datetime.now()
  i = 1 + len(docIds)

  line = input = None
  try:
    input = open(textfile, 'r')
    line = input.readline()
  except:
    print('failed to open: ', textfile)

  while line:
    print(line)
    line = f.readline()
    text = str(i) + '.) ' + line
    # default behavior is to store all ? but since the file is local, let's just store the meta-data if possible ...
    jsonbody = [ {'timestamp': logtime, 'filename': textfile}, {'content': text, 'store': false} ]
    es.index(index=_theIndexName, doc_type='text/plain', id=i, body=jsonbody)
    docIds.append(i) ; print(i)
    i = 1 + i

  input.close()
  return i

def indexTextFileBlob(es, filename='./elastic.py', docIds=[]):
  """
  return entire text from file as a single string and index it
  """
  print(__name__, inspect.getdoc(__name__))

  logtime = datetime.now()
  i = 1 + len(docIds)

  text = input = None
  try:
    input = open(textfile, 'r')
    text = input.read()
  except:
    print('failed to open: ', textfile)
  return

  # default behavior is to store all ? but since the file is local, let's just store the meta-data if possible ...
  jsonbody = [ {'timestamp': logtime, 'filename': textfile}, {'content': text, 'store': false} ]
  es.index(index=_theIndexName, doc_type='text/plain', id=i, body=jsonbody)

  docIds.append(i) ; print(i)
  return i

def indexFiles(es, docIds=[], path='./'):
  """
  Recursively search the specified directory path for all text files and index each file found.
  """
  print(__name__, inspect.getdoc(__name__))
  if( not es ):
    es = connect()

  filelist = []
  cnt = textFileList(filelist, path)
  if( cnt <= 0 ):
    print('sorry, no text files found')
    return None

  i = 1 + len(docIds)
  for f in filelist:
    idx = indexTextFileByLine(i, f)
    i = idx+1

  return len(docIds)

def getById(es, res={}, index=_theIndexName, doc_type='people', docIds=[1,2]):
  """
  Get the document that was indexed, by its Id ... implies ES keeps its own copy of all the full content?
  """
  for i in docIds:
    res[i] = es.get(index=_theIndexName, doc_type='people', id=i)

  return len(res)

def searchMatch(es, content='Darth Vader'):
  # Where is Darth Vader? Here is our search query:
  cont = es.search(index=_theIndexName, body={"query": {"match": {'name':content}}})
  print(repr(cont))
  return cont

def searchPrefix(es, content='lu'):
  # get all documents with prefix 'lu' in their name field:
  lu = es.search(index=_theIndexName, body={"query": {"prefix": {"name":content}}})
  print(repr(lu))
  return lu

def searchFuzzy(es, content='jaba'):
  # get all elements similar in some way, for a related or correction search we can use something like this:
  jaba = es.search(index=_theIndexName, body={ "query": {"fuzzy_like_this_field": { "name": {"like_text": content, "max_query_terms":5}}}})
  print(repr(jaba))
  return jaba

if __name__ == '__main__':
  es = connect()
  if( es == None ):
    print('failed to connect to elasticsearch service')
    sys.exit(1)

