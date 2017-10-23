#!/usr/local/bin/python

import eventlet
eventlet.monkey_patch()

import os
import sys

#If ../cloudbyte/__init__.py exists, add ../ to Python search path, so that
# it will override what happens to be installed in /usr/(local/)lib/python...
POSSIBLE_TOPDIR = os.path.normpath(os.path.join(os.path.abspath(sys.argv[0]),
                                   os.pardir,
                                   os.pardir))
if os.path.exists(os.path.join(POSSIBLE_TOPDIR, 'cloudbyte', '__init__.py')):
  sys.path.insert(0, POSSIBLE_TOPDIR)

from cloudbyte import flags
from cloudbyte import log as logging
from cloudbyte import utils
from cloudbyte import hautils
from cloudbyte import cbcutils

LOG = None

def getListOfVsms():
  vsmConfigList = None
  vsms = []
  haPools = hautils.getAllPools()
  for haPool in haPools:
    vsmConfigList = hautils.getListTSMElementsByPoolElement(haPool)
    for vsmConfig in vsmConfigList:
      vsm = {}
      vsm['uuid'] = vsmConfig['uuid']
      vsm['fibid'] = vsmConfig['fibid']
      vsm['jid'] = cbcutils.getJailIdByUuid(vsmConfig['uuid'])
      vsms.append(vsm)
  return vsms

def generatePatchSteps(vsms):
  patchDir = "/cbdir/patch_1098_iscsi/"
  patchScript = patchDir+"patch_steps.sh"
  newLine = "\n"
  with open(patchScript, "w") as f:
    entry = "#!/bin/sh"+newLine
    f.write(entry)
    for vsm in vsms:
      entry = "jexec "+str(vsm['jid'])+" service istgt onestatus"+newLine
      f.write(entry)
      entry = "sleep 1"+newLine
      f.write(entry)
      entry = "connbefore=`jexec "+str(vsm['jid'])+" netstat -an | grep 3260 | grep EST | wc -l`"+newLine
      f.write(entry)
      entry = "sleep 1"+newLine
      f.write(entry)
      entry = "jexec "+str(vsm['jid'])+" service istgt onestop"+newLine
      f.write(entry)
      entry = "/bin/cp istgt /tenants/"+vsm['uuid'].replace("-","")+"/usr/local/bin/istgt"+newLine
      f.write(entry)
      entry = "/bin/cp istgtcontrol /tenants/"+vsm['uuid'].replace("-","")+"/usr/local/bin/istgtcontrol"+newLine
      f.write(entry)
      entry = "jexec "+str(vsm['jid'])+" setfib "+str(vsm['fibid'])+" service istgt onestart"+newLine
      f.write(entry)
      entry = "sleep 1"+newLine
      f.write(entry)
      entry = "md5sum /tenants/"+vsm['uuid'].replace("-","")+"/usr/local/bin/istgt"+newLine
      f.write(entry)
      entry = "md5sum /tenants/"+vsm['uuid'].replace("-","")+"/usr/local/bin/istgtcontrol"+newLine
      f.write(entry)
      entry = "sleep 5"+newLine
      f.write(entry)
      entry = "jexec "+str(vsm['jid'])+" service istgt onestatus"+newLine
      f.write(entry)
      entry = "sleep 1"+newLine
      f.write(entry)
      entry = "connafter=`jexec "+str(vsm['jid'])+" netstat -an | grep 3260 | grep EST | wc -l`"+newLine
      f.write(entry)
      entry = "sleep 1"+newLine
      f.write(entry)
      entry = "echo $connbefore $connafter"+newLine
      f.write(entry)
      entry = "echo \"\""+newLine
      f.write(entry)
      entry = "sleep 10"+newLine+newLine
      f.write(entry)
    entry = "/bin/cp tsmutils.py /usr/local/agent/cloudbyte/tsmutils.py"+newLine
    f.write(entry)
    entry = "service cbc_storageconfiguration onerestart"+newLine
    f.write(entry)
    entry = "sleep 3"+newLine
    f.write(entry)
    entry = "service cbc_storageconfiguration onestatus"+newLine
    f.write(entry)
  return 0

if __name__ == '__main__':
  utils.default_flagfile()
  flags.FLAGS(sys.argv)

  #Set rabbit retries to 3. Default is 0, which will try infinitely for connecting rabbitmq server. 
  flags.FLAGS.rabbit_max_retries = 3

  LOG_DIR = flags.FLAGS.logdir
  flags.FLAGS.logfile = 'generate_patch_steps.log'
  if not os.path.exists(LOG_DIR):
    os.mkdir(LOG_DIR)
  logging.setup()
  utils.monkey_patch()

  LOG = logging.getLogger("cloudbyte.generate_patch_steps")

  LOG.info(_("Generating patch steps..."))

  # Get list of VSMs and their fibids.
  vsms = getListOfVsms()
  # Generate patch_steps.sh
  generatePatchSteps(vsms)
