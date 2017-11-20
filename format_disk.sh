#!/bin/sh
##This script will format the new disk.
#Usages:sh format.sh da(number).EG- sh format.sh da2 
if [ $# -lt 1 ]
then
 echo "Usages: $0 danumber"
 exit;
fi
number=$1
timestamp=$(date +"%d%h%Y_%H%M")
FILE=/root/support/"newdisk_$timestamp"
mkdir -p $FILE
procstat -kka > $FILE/proc.out.1
grep "dnode_special_close" $FILE/proc.out.1
if [ $? -eq 0 ]
then
  echo "Please contact CloudByte Support"
  echo "Cannot proceed as dnode_special_close situation on Node"
  exit
fi
pgrep "zpool|zfs|gmultipath|smartctl|sg_persist" 
if [ $? -eq 0 ]
then
 count=1
 while [ $count -lt 11 ]
 do
  echo $count
  sleep 1
  pgrep "zpool|zfs|gmultipath|smartctl|sg_persist"
  if [ $? -ne 0 ]
  then
    break
  fi
  count=`expr $count + 1`
  if [ $count -eq 11 ]
  then
    echo"Cannot format the disk as command are in hang state "
    exit
    fi
 done
fi
cd $FILE
echo "Executing zpool status"
zpool status > $FILE/zpoolstatus.out   
echo "camcontrol output"
camcontrol devlist > $FILE/cam.out
echo "Executing gmultipath status"
gmultipath status > $FILE/gmultipath.out 
echo "smartctl output of disk "
smartctl -x -T permissive /dev/$number > $FILE/smart_$number.out 
echo $number
grep $number gmultipath.out
if [ $? -eq 0 ]
then
    echo "Check the da path is correct as it already labelled"
    echo "Else please contact CloudByte Support"
    exit
else
    echo "Starting formatting of disk " 
    echo "Collected files are located at "$FILE
    nohup camcontrol format /dev/$number -qy > /dev/null 2>&1 & 
    echo "Camcontrol format will take some to complete"
    echo "You can check the status using the below command"
    echo "## camcontrol format /dev/$number -r ##"
   exit
fi 
