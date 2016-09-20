#!/usr/local/bin/python

import os
tmpFdOpen = os.fdopen
os.fdopen = tmpFdOpen

import sys
import argparse

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
from cloudbyte import cbxmlutils as cbxml
from cloudbyte import XMLLibrary as Xml

def copyPoolConfig(srcConfigXml, dstConfigXml, poolId):
  try:
    poolList = cbxml.getListOfElementsWithChildTagFilter(srcConfigXml, "//cloudbyte/zfs/pools/pool", childTag='uuid', childText=poolId)
    if (len(poolList) == 0):
      msg = "Pool with id: "+str(poolId)+" is not found in "+str(srcConfigXml)
      LOG.debug(msg)
      return -1
    if (len(poolList) > 1):
      msg = "More than one pool with id: "+str(poolId)+" exists in "+str(srcConfigXml)+". Invalid."
      LOG.debug(msg)
      return -1
    pool = poolList[0]
  
    #copy pool element
    poolPath = '//cloudbyte/zfs/pools/pool'
    poolIndex = cbxml.getIndexId(srcConfigXml, poolId, poolPath, 'uuid')
    poolXPath = poolPath+'['+str(poolIndex)+']'
    cbxml.copySubTree(srcConfigXml, poolXPath, dstConfigXml, './zfs/pools')
  
    #copy vdevices
    vDevList = cbxml.getListOfLeafElement(srcConfigXml, poolXPath, 'vdevice')
    vdevicesNode = cbxml.checkPathInXML(dstConfigXml, '//cloudbyte/zfs/vdevices')
    if vdevicesNode == 1:
      cbxml.createSubParent(dstConfigXml, 'zfs', 'vdevices')
    for vDevUuid in vDevList:
      vDevPath = '//cloudbyte/zfs/vdevices/vdevice'
      vDevIndex = cbxml.getIndexId(srcConfigXml, vDevUuid, vDevPath, 'uuid')
      vDevXPath = vDevPath+'['+str(vDevIndex)+']'
      cbxml.copySubTree(srcConfigXml, vDevXPath, dstConfigXml, './zfs/vdevices')
  
    #copy datasets and tenants
    poolName = pool['name']
    datasetList = cbxml.getListOfElementsWithChildTagFilter(srcConfigXml, "//cloudbyte/zfs/datasets/dataset", childTag='mypool', childText=poolName)
    if (len(datasetList) == 0):
      msg = "No datasets are found for pool "+str(poolName)+" in "+str(srcConfigXml)  
      LOG.debug(msg)
      return 0
    datasetsNode = cbxml.checkPathInXML(dstConfigXml, '//cloudbyte/zfs/datasets')
    if datasetsNode == 1:
      cbxml.createSubParent(dstConfigXml, 'zfs', 'datasets')
    tenantsNode = cbxml.checkPathInXML(dstConfigXml, '//cloudbyte/tenants')
    if tenantsNode == 1:
      cbxml.createSubParent(dstConfigXml, '', 'tenants')
    for dataset in datasetList:
      dsUuid = dataset['uuid']
      dsPath = '//cloudbyte/zfs/datasets/dataset'
      dsIndex = cbxml.getIndexId(srcConfigXml, dsUuid, dsPath, 'uuid')
      dsXPath = dsPath+'['+str(dsIndex)+']'
      cbxml.copySubTree(srcConfigXml, dsXPath, dstConfigXml, './zfs/datasets')
      tsmUuid = dataset['tntuuid']
      tsmPath = '//cloudbyte/tenants/tenant'
      tsmIndex = cbxml.getIndexId(srcConfigXml, tsmUuid, tsmPath, 'uuid')
      tsmXPath = tsmPath+'['+str(tsmIndex)+']'
      cbxml.copySubTree(srcConfigXml, tsmXPath, dstConfigXml, './tenants')
  except Exception:
    LOG.exception("[copyPoolConfig]: Failed to change pool ownership.")
    return -1

  return 0



def removePoolConfig(srcConfigXml, poolId):
  try:
    #copy pool element
    poolPath = '//cloudbyte/zfs/pools/pool'
    poolIndex = cbxml.getIndexId(srcConfigXml, poolId, poolPath, 'uuid')
    poolXPath = poolPath+'['+str(poolIndex)+']'
    poolList = cbxml.getListOfElementsWithChildTagFilter(srcConfigXml, "//cloudbyte/zfs/pools/pool", childTag='uuid', childText=poolId)
    if (len(poolList) == 0):
      msg = "[Remove pool config]: Pool with id: "+str(poolId)+" is not found in "+str(srcConfigXml)
      LOG.debug(msg)
      return -1
    if (len(poolList) > 1):
      msg = "[Remove pool config]: More than one pool with id: "+str(poolId)+" exists in "+str(srcConfigXml)+". Invalid."
      LOG.debug(msg)
      return -1
    pool = poolList[0]
    poolName = pool['name']
  
    #delete pool entry
    Xml.deletePoolXML(srcConfigXml, poolId)        
    LOG.debug("[Remove pool config]: pool removed")      
    
    #remove all tennant entry
    tsmList = cbxml.getListOfElementsWithChildTagFilter(srcConfigXml, "//cloudbyte/tenants/tenant", childTag='mypool', childText=poolName)
    if (len(tsmList) == 0):
      msg = "[Remove pool config]: No VSM are found for pool "+str(poolName)+" in "+str(srcConfigXml)  
      LOG.debug(msg)
    else:
      LOG.debug(_("length of VSM is %s"),str(len(tsmList)))  
      for tsm in tsmList:
        LOG.debug(_("VSM %s removing from conf=%s"),str(tsm['uuid']),str(srcConfigXml))  
        tsmUuid = tsm['uuid']
        tsmPath = '//cloudbyte/tenants/tenant'
        Xml.deleteTsmXML(srcConfigXml, '//cloudbyte/tenants/tenant',tsmUuid)
      LOG.debug("[Remove pool config]: All VSM removed from previous owner of pool")      
    
    #remove all dataset entry
    datasetList = cbxml.getListOfElementsWithChildTagFilter(srcConfigXml, "//cloudbyte/zfs/datasets/dataset", childTag='mypool', childText=poolName)
    if (len(datasetList) == 0):
      msg = "[Remove pool config]: No datasets are found for pool "+str(poolName)+" in "+str(srcConfigXml)  
      LOG.debug(msg)
    else:
      for dataset in datasetList:
        dsUuid = dataset['uuid']
        dsPath = '//cloudbyte/zfs/datasets/dataset'
        dsIndex = cbxml.getIndexId(srcConfigXml, dsUuid, dsPath, 'uuid')
        dsXPath = dsPath+'['+str(dsIndex)+']'
        storagePathNode = '//cloudbyte/zfs/datasets/dataset[' + str(dsIndex) + ']/path'
  
        check = cbxml.checkPathInXML(srcConfigXml, storagePathNode)
        if check == 0:
          storagePath = cbxml.getValue(srcConfigXml, storagePathNode)  
          Xml.deleteStorageXML(srcConfigXml, '//cloudbyte/zfs/datasets/dataset',dsUuid,storagePath)
      LOG.debug("[Remove pool config]: All dataset removed from previous owner of pool")      
  except Exception:
    LOG.exception("[removePoolConfig]: Failed to change pool ownership.")
    return -1

  return 0  

def is_valid_file(parser, arg):
    if not os.path.exists(arg):
        parser.error("The file %s does not exist!" % arg)
    else:
      return arg
 
argument = ['-src', '-dest' , '-poolid']
def getCommandLineArgs():
  parser = argparse.ArgumentParser(description='This is to change Pool ownership in xml.')
  parser.add_argument(argument[0],  help='Enter source file name, where pool configuration exist.', required=True, metavar="FILE", type=lambda x: is_valid_file(parser, x))
  parser.add_argument(argument[1],  help='Enter destination file, where pool configuration need to copy.',required=True,  metavar="FILE", type=lambda x: is_valid_file(parser, x))

  parser.add_argument(argument[2],  help='Enter Pool uuid whose configuration need to move.', required=True)
  args = parser.parse_args()
  src = args.src
  dest = args.dest
  poolId = args.poolid
  return src, dest, poolId


if __name__ == '__main__':
  #source file(src) from where pool configuration need to move to destination file(dest)
  src, dest, poolId = getCommandLineArgs()
  utils.default_flagfile()
  sysArgs=[]
  for a in sys.argv:
    if not (a in argument):
      sysArgs.append(a)
  #Flags file giving error if we are using "-" option with command line args
  flags.FLAGS(sysArgs)
  LOG_DIR = flags.FLAGS.logdir
  flags.FLAGS.logfile = 'test_Move_Pool_Config.log'
  if not os.path.exists(LOG_DIR):
    os.mkdir(LOG_DIR)
  logging.setup()
  LOG = logging.getLogger('cloudbyte.test_Move_Pool_Config')
  utils.monkey_patch()
  LOG.info(_("Move pool configuration, source file= %s, destination file=%s, poolId=%s"),str(src),str(dest),str(poolId))
  status = copyPoolConfig(src, dest, poolId)
  if status != 0:
    print "Failed to copy configuration to "+str(dest)+". Check xml and logs to find issue."
    exit(1)
  removestatus=removePoolConfig(src, poolId)
  if status != 0:
    print "Failed to copy configuration to "+str(dest)+". Check xml and logs to find issue."
    exit(1)
  print "Successfully moved configuration from '"+str(src)+"' to '"+str(dest)+"'."
  exit(0)
