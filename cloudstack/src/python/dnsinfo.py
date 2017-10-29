#!/usr/bin/env python
"""
DNSinfo module should support forward and reverse lookups of one or more IPs
and domain names.
"""
from __future__ import print_function

import pprint, socket, sys, timeit
if(sys.version_info.major < 3):
  import six # allows python3 syntax in python2

def dnsinfo(ip='10.101.8.92'):
  """
  DNSinfo returns the domain name(s) found for an individual IP
  """
  dns = None
  try:
    dns = socket.gethostbyaddr(ip)
  except:
    print('oops no dns entry for: ', ip)
  print(ip, dns)
  return dns
#end dnsinfo

def alldns(dnshash={}, subnet=[10,101,8]):
  """
  Alldns returns a hash dict. of all domain-names for each IP (key) in a subnet.
  The subnet should be provided as a list. TBD: check whether subne is class A
  or B or C by using len(subnet)
  """
  i = 2
  ips = str(subnet[0]) + '.' + str(subnet[1]) + '.' +  str(subnet[2]) + '.'
  while( i < 255):
    ip = ips + str(i)
    dns = dnsinfo(ip) ; dnshash[ip] = dns
    i += 1
  #endwhile
#endmain

if __name__ == '__main__':
  info = {} ; net = [10,101,8]
#  main() ;  # main(info)
  alldns(info, net)
# pp = pprint.PrettyPrinter(indent=2)
# pprint.pprint(info)
