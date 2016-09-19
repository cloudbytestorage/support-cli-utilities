# Cli Utilities for CloudByte ElastiStor 

These are a bunch of scripts, each of which can be executed independently and will help the administrators perform management or support tasks on the CloudByte ElastiStor. 

## Install by Downloading from browser

### Step 1 : Download the utilities. 
* Goto the page : https://github.com/cloudbytestorage/support-cli-utilities
* Use the "Clone or Download" button on the top right corner and Click on "Download ZIP"
* A file called "support-cli-utilities-master.zip" will be downloaded to your computer. 
* Transfer the file to your ElastiStor node, say into /root/support-cli-utilities-master.zip

### Step 2 : Extract the files 
```
#$cd /root
#$unzip support-cli-utilities-master.zip
#$cd support-cli-utilities-master
```
### Step 3 : Run the required script. For example:
```
#$cd /root/support-cli-utilities-master
#$sh zpool_mos_arc_usage.sh
POOL: Bucket1
  Arc Limit  : 536870912
  Arc Used   : 68.35
  Arc Missed : 0
POOL: Support
  Arc Limit  : 536870912
  Arc Used   : 370.82
  Arc Missed : 0
POOL: tpool
  Arc Limit  : 536870912
  Arc Used   : 1.60
  Arc Missed : 0
```
