#!/bin/sh

# Display the current IO stats of all the volumes in a given pool
# Usage: sh pool_volumes_io.sh <pool_name> [duration]

if [ $# -lt 1 ] ; then
  echo "Usage sh pool_volumes_io.sh <pool_name> [duration]"
  exit 1
fi

#Use 10 seconds as interval between the stats capture.
duration=10
if [ $# -gt 1 ] ; then
  duration=$2
fi

#Validate the pool id
rv=`zpool list | awk '{print $1}' | grep $1 `
if [ $? -ne 0 ] ; then
  echo "Unable to find the Pool($1) on this node"
  exit
fi

pool=$1

#Create a temporary directory to store the collected stats
day=`date | tr -s " " | cut -f 2 -d  " "`
dt=`date | tr -s " " | cut -f 3 -d  " "`
ts=`date +%s`
sep="_"
CWD=`pwd`
BACKUP_DIR="RENG_$day$dt$sep$ts"
mkdir -p "${CWD}/$BACKUP_DIR"

#Collect stats on only the volumes
volumes=`zfs list | grep "$pool" | awk '{print $1}' | xargs`
volregexp="\b(.*)\/(.*)\/(.*)\b"

echo "Name type Reads Writes Staggered" >> "${CWD}/$BACKUP_DIR/reng.stats"
for vol in $volumes
do
  isvol=`echo $vol | egrep $volregexp`
  if [ $? -eq 0 ] ; then
    volname=`echo $vol | awk -F '/' '{print $3}'`
    #echo "Gathering stats for $volname"
    reng stats access dataset $vol qos > "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname"
    pr=`grep "Reads" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $2}'`
    pw=`grep "Writes" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $2}'`
    prb=`grep "Read Size"  "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $3}'`
    pwb=`grep "Write Size"  "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $3}'`
    ps=`grep "IO staggered" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | awk '{print $3}'`
    pmr=`grep "Metadata Reads" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | awk '{print $3}'`
    pmw=`grep "Metadata Writes" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | awk '{print $3}'`
    pd=`grep "Remove Count" "${CWD}/$BACKUP_DIR/prev.reng.stats.$volname" | awk '{print $3}'`    
    echo "$volname prev $pr $pw $prb $pwb $ps" >> "${CWD}/$BACKUP_DIR/reng.stats"
  fi
done

echo "Waiting for $duration..."
sleep $duration

for vol in $volumes
do
  isvol=`echo $vol | egrep $volregexp`
  if [ $? -eq 0 ] ; then
    #echo "Gathering stats for $volname"
    volname=`echo $vol | awk -F '/' '{print $3}'`
    reng stats access dataset $vol qos > "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname"
    cr=`grep "Reads"  "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $2}'`
    cw=`grep "Writes"  "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $2}'`
    crb=`grep "Read Size"  "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $3}'`
    cwb=`grep "Write Size"  "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | grep -v "Meta\|Disk" | awk '{print $3}'`
    cs=`grep "IO staggered"  "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | awk '{print $3}'`
    cmr=`grep "Metadata Reads" "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | awk '{print $3}'`
    cmw=`grep "Metadata Writes" "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | awk '{print $3}'`
    cd=`grep "Remove Count" "${CWD}/$BACKUP_DIR/curr.reng.stats.$volname" | awk '{print $3}'`
    echo "$volname curr $cr $cw $crb $cwb $cs" >> "${CWD}/$BACKUP_DIR/reng.stats"
  fi
done


#Check for the difference between the current and previous values
echo "Name Reads Writes RBytes WBytes Staggered MetaReads MetaWrites Deletes"
for vol in $volumes
do
  isvol=`echo $vol | egrep $volregexp`
  if [ $? -eq 0 ] ; then
    volname=`echo $vol | awk -F '/' '{print $3}'`
    pr=`grep "^$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $3}'`
    pw=`grep "^$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $4}'`
    prb=`grep "^$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $5}'`
    pwb=`grep "^$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $6}'`
    ps=`grep "^$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $7}'`
    pmr=`grep "^$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $8}'`
    pmw=`grep "^$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $9}'`
    pd=`grep "^$volname prev" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $10}'`

    cr=`grep "^$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $3}'`
    cw=`grep "^$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $4}'`
    crb=`grep "^$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $5}'`
    cwb=`grep "^$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $6}'`
    cs=`grep "^$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $7}'`
    cmr=`grep "^$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $8}'`
    cmw=`grep "^$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $9}'`
    cd=`grep "^$volname curr" ${CWD}/$BACKUP_DIR/reng.stats | awk '{print $10}'`

    tr=`echo $cr - $pr | bc`
    tw=`echo $cw - $pw | bc`
    trb=`echo $crb - $prb | bc`
    twb=`echo $cwb - $pwb | bc`
    ts=`echo $cs - $ps | bc`
    tmr=`echo $cmr - $pmr | bc`
    tmw=`echo $cmw - $pmw | bc`
    td=`echo $cd - $pd | bc`
    echo "$volname diff $tr $tw $trb $twb $ts $tmr $tmw $td" >> "${CWD}/$BACKUP_DIR/reng.stats"
    echo "$volname $tr $tw $trb $twb $ts $tmr $tmw $td" 
  fi
done
