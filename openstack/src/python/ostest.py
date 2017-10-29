#!/usr/bin/env python
import os

def oscreds():
  cred = {}
  cred['username'] = os.environ['OS_USERNAME']
  cred['password'] = os.environ['OS_PASSWORD']
  cred['auth_url'] = os.environ['OS_AUTH_URL']
  cred['tenant_name'] = os.environ['OS_TENANT_NAME']
  cred['project_id'] = os.environ['OS_TENANT_NAME']
  return cred

