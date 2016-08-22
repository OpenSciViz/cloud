#!/bin/bash
echo "usage: source ./pysetup.sh [2 or 3]"
which python python2 python3
#
alias py2venv='/Library/Frameworks/Python.framework/Versions/2.7/bin/virtualenv -p /Library//Frameworks/Python.framework/Versions/2.7/bin/python --clear --always-copy --prompt=py2env'
alias py3venv='/Library/Frameworks/Python.framework/Versions/3.5/bin/virtualenv -p /Library//Frameworks/Python.framework/Versions/3.5/bin/python3 --clear --always-copy --prompt=py3env'
#
# default is python 2 (2.7.11 latest)
version=2
#
if [ "$1" != "" ] ; then version="$1" ; fi
if [ $version -le 2 ] ; then
  version=2
  py2venv ./py${version}env
fi
if [ $version -ge 3 ] ; then
  version=3
  py3venv ./py${version}env
fi
#
. ./py${version}env/bin/activate
which python python2 pip2 python3 pip3

pypip="pip${version} install" # ; echo "pypip == $pypip"
modules='gitpython cloudmonkey python-redmine sphinx recommonmark pyroute2 pillow matplotlib openpyxl flask-socketio'

# https://github.com/rtfd/recommonmark - provides markdown support for sphinx
# add to sphinx conf.py:
# from recommonmark.parser import CommonMarkParser
# source_parsers = {
#   '.md': CommonMarkParser,
#}
#source_suffix=['.rst', '.md'] # ; echo $source_suffix

echo install useful modules via $pypip ... $modules
$pypip $modules
