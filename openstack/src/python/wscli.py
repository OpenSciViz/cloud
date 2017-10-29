#!/usr/bin/env python

import sys

from ws4py.client.threadedclient import WebSocketClient

class LazyClient(WebSocketClient):
  def run(self):
    try:
      while not self.terminated:
        try:
          b = self.sock.recv(4096)
          sys.stdout.write(b)
          sys.stdout.flush()
        except: 
          pass # socket error expected
    finally:
      self.terminate()

if __name__ == '__main__':
  if len(sys.argv) != 2 or not sys.argv[1].startswith("ws"):
    print "Usage %s: Please use websocket url"
    print "Example: ws://127.0.0.1:6083/?token=xxx"
    exit(1)
  try:
    ws = LazyClient(sys.argv[1], protocols=['binary'])
    ws.connect()
    while True:
      # keyboard event...
      c = sys.stdin.read(1)
      if c:
        ws.send(c)
      ws.run_forever()
  except KeyboardInterrupt:
    ws.close()

