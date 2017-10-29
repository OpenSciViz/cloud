#!/usr/bin/env python
"""
A simple http service to support Cloudstack ISO and VM Template registration URLs,
since file:// URLs are not supported ... need http:// ...
Refs: http://stackoverflow.com/questions/24318084/flask-make-response-with-large-files
and  http://flask.pocoo.org/docs/0.11/api/#flask.send_from_directory
and https://github.com/seb-m/pyinotify/wiki

Start http service:
./filesrv.py
....... OR ........
which flask
if [ $? == 0 ] ; then
  export FLASK_DEBUG=1 && export FLASK_APP=`pwd`/filesrv.py && flask run --host=0.0.0.0 --port=80
fi
....... OR ........
which gunicorn
if [ $? == 0 ] ; then
  # foreground:
  gunicorn filesrv:app -b 0.0.0.0:80
  # daemonize and store daemon pid
  # gunicorn filesrv:app -b 0.0.0.0:80 -D -p filesrv.pid
fi
"""

from __future__ import print_function
import os, string, sys
if sys.version_info.major < 3: import six # allows python3 syntax in python2

import datetime, errno, getopt, json, logging, signal, socket, time, zipfile
#import inotify.adapters
import pyinotify

import flask
from werkzeug.exceptions import HTTPException, NotFound
from werkzeug.contrib.fixers import ProxyFix

app = flask.Flask(__name__)
#app.wsgi_app = ProxyFix(app.wsgi_app)
app.config.from_object(__name__)
app.config['TRAP_HTTP_EXCEPTIONS']=True

app.config['KVMimages'] = _rootdir = '/home/david.hon/KVMimages'
app.config['Filelist'] = _filelist = []
app.config['Host'] = _host = socket.getfqdn()

from logging.handlers import RotatingFileHandler
#_logFilehandler = _logformat = None
_logformat = None

_now = datetime.datetime.now().strftime("%j.%Y.%H.%M.%S")

def basiclog(logfile):
  global _logformat
  global _now
# _logformat = '[%(asctime)s] {%(pathname)s:%(lineno)d} %(levelname)s - %(message)s'
  _logformat = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
  logging.basicConfig(level=logging.DEBUG, format=_logformat,
                      datefmt='%y.%m.%d.%H.%M', filemode='w',
                      filename=logfile) # filename='/var/tmp/'+__file__+_now+'.log')
  return _logformat

def initlog():
  global app
  global _now
  global _logformat
  logfile_date = 'www' + _now + '.log'
  logfile = 'www.log'

# http://blog-archive.copyninja.info/2012/08/logging_issue_with_flask.html -- indicates loglevel must be set uniformly for all logger?
  loglevel = logging.DEBUG # above example sets the level before adding handler

  _logformat = '%(asctime)s - %(pathname)s:%(lineno)d - %(name)s - %(levelname)s - %(message)s'
  _logformat = logging.Formatter(_logformat)

# logFilehandler = logging.FileHandler(logfile_date) 
  logFilehandler = RotatingFileHandler(logfile, maxBytes=10000, backupCount=99)
  logFilehandler.setFormatter(_logformat)
  logFilehandler.setLevel(loglevel)

  logStreamhandler = logging.StreamHandler()
  logStreamhandler.setFormatter(_logformat)
  logStreamhandler.setLevel(loglevel)

# add log handler to flask app logger and werkzeug and __name__:
  app.logger.setLevel(loglevel)
  app.logger.addHandler(logFilehandler) ; app.logger.addHandler(logStreamhandler)
  logHTTPhandler = logging.getLogger('werkzeug')
  logHTTPhandler.setLevel(loglevel)
# this seems to be the only logger that works?
  logHTTPhandler.addHandler(logFilehandler) ; logHTTPhandler.addHandler(logStreamhandler)
  logging.getLogger(__name__).addHandler(logFilehandler) ; logging.getLogger(__name__).addHandler(logStreamhandler)
#end initlog

def infolog(*args, **kwargs):
  global app
  if not _logformat: initlog() # basiclog()
  try:
    print(__file__, *args, file=sys.stderr, **kwargs)
#   app.logger.info(*args, **kwargs)
#   log = logging.getLogger(__name__) ; log.info(*args, **kwargs)
    logging.info(*args, **kwargs)
  except:
    logging.exception('infolog> logging exception?')
#end infolog

class InotifyEventHandler(pyinotify.ProcessEvent):
  def process_IN_CREATE(self, event):
    infolog("Creating:", event.name) # infolog("Creating:", event.pathname)
    if event.name not in _filelist: _filelist.append(event.name)

# def process_IN_MODIFY(self, event):
#   infolog("Modifying:", event.name) # infolog("Modifying:", event.pathname) 
#   if event.name not in _filelist: _filelist.append(event.name)

  def process_IN_DELETE(self, event):
    infolog("Removing:", event.name) # infolog("Removing:", event.pathname)
    if event.name in _filelist: _filelist.remove(event.name)
#end class

def monitor_uploads(watchme=_rootdir):
  wm = pyinotify.WatchManager()  # Watch Manager
  mask = pyinotify.IN_CREATE | pyinotify.IN_MODIFY | pyinotify.IN_DELETE  # watched events
  infolog('monitor_uploads> ', 'starting inotify watch on: ', watchme)
  notifier = pyinotify.ThreadedNotifier(wm, InotifyEventHandler())
  notifier.start()
  wdd = wm.add_watch(watchme, mask, rec=True)
# wm.rm_watch(wdd.values())
# notifier.stop()
#end monitor_uploads

def htmlist(list=[], endpoint='/KVMimages', path=None):
  global _host
  # test default list of ISOs:
  if len(list) <= 0: list = [ 'CentOS-6.4-x86_64-minimal.iso', 'CentOS-6.5-x86_64-LiveDVD.iso' ]
  infolog('list: ', list, endpoint, path)
  urlist = []
  for item in list:
    url = '<a href="http://'+_host+endpoint+'/'+item+'">'+item+'</a><br/>'
    #infolog('htmlist> ', url)
    urlist.append(url)
  #endfor
  html = ''.join(urlist)
  infolog('htmlist> ', html)
  return html
#end htmlist

# 1-time startup setup:
def startup():
  global _rootdir, _filelist
  infolog(_rootdir, ' ... starting Flask http web server ...')
  monitor_uploads(_rootdir)
  for dirname, subdirs, files in os.walk(_rootdir):
    try:
      for filename in files:
        #infolog(_rootdir, dirname, subdirs, filename)
        ignore = string.lower(filename)
        img = string.find(ignore, '.img') ; iso = string.find(ignore, '.iso') ; qcow = string.find(ignore, '.qcow')
        if( img == -1 and iso == -1 and qcow == -1 ): continue
        # filepath = os.path.join(dirname, filename) ; absname = os.path.abspath(filepath)
        _filelist.append(filename) # _filelist.append(filepath)
      #endfor filename
    except: pass
  #endfor dirname
  htmlist(_filelist)
#end startup

# handler for all http and internal errors
@app.errorhandler(Exception)
def handle_error(e):
  try:
    if e.code < 400:
      return flask.Response.force_type(e, flask.request.environ)
    raise e
  except:
    return flask.make_response('<p>Bad request or worse ... ,/p>')
#end handle_error

# welcome / main page return directory listing
@app.route('/', defaults={'path': ''})
@app.route('/<path:path>') # catch-all URL
@app.route('/KVMimages')
def dirList(path='/KVMimages'):
  global _filelist
  if len(_filelist) <= 0: startup()
  return htmlist(_filelist, '/KVMimages', path)

@app.route('/KVMimages/<path:filename>', methods=['GET', 'POST'])
# below is async threaded:
def streamFile(filename):
  global _rootdir
  infolog('streamFile> ', _rootdir, filename)
  file = None ; fsize = '0'
  try:
    file = open(filename, 'rb')
    fsize = str(os.path.getsize(filename))
  except:
    infolog('streamFile> sorry, failed to open and read file:', filename)  
    return flask.make_response('<p>File access error: ' + _rootdir + '/' + filename + '</p>', 400) # (flask.request.environ)

  content_length = 4096 
  def generate():
    try:
      while True:
        chunk = file.read(content_length)
        if len(chunk) == 0: 
          f.close()
          return
        yield chunk
    except: pass
  #end generate stream
  resp = flask.Response(flask.stream_with_context(generate()), mimetype='application/octet-stream')
  # ok this works with wget and curl:
  resp.headers['Content-Length'] = fsize # str(content_length)
  return resp
#end streamFile

if __name__ == '__main__':
  startup()
# app.run(host='0.0.0.0', port=80, threaded=True)
# http://stackoverflow.com/questions/28925451/flask-logging-not-working-at-all
  app.run(host='0.0.0.0', port=80, threaded=True, debug=True)

