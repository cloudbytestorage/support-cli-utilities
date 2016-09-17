#!/bin/sh

# Display the throttling counters on the volumes in a given vsm
# Usage: sh check_vsm_throttling.sh <jid|ip address> [duration]

if [ $# -lt 1 ] ; then
  echo "Usage sh check_vsm_throttling.sh <jid|ip address> [duration]"
  exit 1
fi

#Use 10 seconds as interval between the stats capture.
duration=10
if [ $# -gt 1 ] ; then
  duration=$2
fi

#Get the jid, if an IP address is provided
jid=$1
ipregexp="\b(.*)\.(.*)\.(.*)\.(.*)\b"
rv=`echo $jid | egrep $ipregexp`
if [ $? -eq 0 ] ; then
  echo "$jid is an ip address"
  jid=`jls | grep $jid | awk '{print $1}'`
  if [ -z $jid ] ; then
    echo "Unable to find an VSM corresponding to IP Address $1"
    exit
  fi
fi

#Validate the jid is valid on this node
rv=`jexec $jid date`
if [ $? -ne 0 ] ; then
  echo "Unable to find the VSM corresponding to $1"
  exit
fi

#Create a temporary directory to store the collected stats
day=`date | tr -s " " | cut -f 2 -d  " "`
dt=`date | tr -s " " | cut -f 3 -d  " "`
ts=`date +%s`
sep="_"
CWD=`pwd`
BACKUP_DIR="RENG_$day$dt$sep$ts"
mkdir -p "${CWD}/$BACKUP_DIR"

#Collect stats on only the volumes
volumes=`jexec $jid zfs list | grep -v "NAME\|tpool" | awk '{print $1}' | xargs`
volregexp="\b(.*)\/(.*)\/(.*)\b"

echo "Name type Reads Writes Staggered" >> "${CWD}/$BACKUP_DIR/reng.stats"
for vol in $volumes
do
  isvol=`echo $vol | egrep $volregexp`
  if [ $? -eq 0 ] ; then
    volname=`echo $vol | awk -F '/' '{print $3}'`
    echo "Gathering stats for $volname"
    reng stats access dataset $vol qos > "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname"
    pr=`grep "Reads" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $2}'`
    pw=`grep "Writes" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $2}'`
    ps=`grep "IO staggered" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | awk '{print $3}'`
    echo "$volname prev $pr $pw $ps" >> "${CWD}/$BACKUP_DIR/reng.stats"
  fi
done

echo "Waiting for $duration..."
sleep $duration

for vol in $volumes
do
  isvol=`echo $vol | egrep $volregexp`
  if [ $? -eq 0 ] ; then
    echo "Gathering stats for $volname"
    volname=`echo $vol | awk -F '/' '{print $3}'`
    reng stats access dataset $vol qos > "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname"
    cr=`grep "Reads"  "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $2}'`
    cw=`grep "Writes"  "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $2}'`
    cs=`grep "IO staggered"  "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | awk '{print $3}'`
    echo "$volname curr $cr $cw $cs" >> "${CWD}/$BACKUP_DIR/reng.stats"
  fi
done


#Check for the difference between the current and previous values
echo "Name Reads Writes Staggered"
for vol in $volumes
do
  isvol=`echo $vol | egrep $volregexp`
  if [ $? -eq 0 ] ; then
    volname=`echo $vol | awk -F '/' '{print $3}'`
    pr=`grep "$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $3}'`
    pw=`grep "$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $4}'`
    ps=`grep "$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $5}'`
    cr=`grep "$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $3}'`
    cw=`grep "$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $4}'`
    cs=`grep "$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $5}'`
    tr=`echo $cr - $pr | bc`
    tw=`echo $cw - $pw | bc`
    ts=`echo $cs - $ps | bc`
    echo "$volname diff $tr $tw $ts" >> "${CWD}/$BACKUP_DIR/reng.stats"
    echo "$volname $tr $tw $ts" 
  fi
done


