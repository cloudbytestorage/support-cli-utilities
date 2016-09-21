#!/bin/sh

#############################################################################################
# Usage: sh check_iops.sh <dataset-name> <iops_limit_to_check>
# Eg.: nohup sh check_iops.sh SSDR50P08/MMPL3775MMPL_3775/MMPL_Vol01 >> mmpl_vol01.out &
# Note: If iops_limit_to_check is not set it will be set the variable defined below
#############################################################################################

dsname="$1"
limit="$2"
#if [ $# -lt 1  || @# -gt 2 ]
if [ $# -lt 1 ]
then
 echo "Enter the dataset-name";
 echo "Usage: $0 <dataset-name> <iops_limit_to_check>"
 exit;
fi

if [ -z $2 ]
then
  limit=1000
  echo "$2 is null . Setting IOPS limit to $limit"
fi
#cmd="reng stats access dataset $dsname qos | grep 'Reads\|Writes\|IO\ throttled\|IO\ staggered' | grep -v 'Disk'"
cmd="reng stats access dataset $dsname qos | grep 'Reads\|Writes\|IO\ throttled\|IO\ staggered\|Disk\ Read\ Size\|Disk\ Write\ Size' | grep -v 'Disk\ Reads\|Disk\ Writes'"
#echo $cmd
stats=`eval ${cmd}`

nreads=`echo "$stats" | grep 'Reads' | awk '{print $2}'`
nwrites=`echo "$stats" | grep 'Writes' | awk '{print $2}'`
nthrottled=`echo "$stats" | grep 'throttled' | awk '{print $3}'`
nstaggered=`echo "$stats" | grep 'staggered' | awk '{print $3}'`
nreadsize=`echo "$stats" | grep 'Read\ Size' | awk '{print $4}'`
nwritesize=`echo "$stats" | grep 'Write\ Size' | awk '{print $4}'`
nreadwritesize=`echo "$nreadsize + $nwritesize" | bc`
#echo `date +%Y%m%d%H%M%S`, $nreads, $nwrites , $nthrottled, $nstaggered , $nreadsize, $nwritesize, $nreadwritesize, 0 , 0
echo "Date_YYMMDD,Time_HHMMSS, Reads, Writes , Throttled, Staggered , ReadSize, WriteSize, Read_Write_BlockSize, Realized IOPS , Exceeded IOPS"

preads=$nreads
pwrites=$nwrites
pthrottled=$nthrottled
pstaggered=$nstaggered
preadsize=$nreadsize
pwritesize=$nwritesize
preadwritesize=$nreadwritesize

while true; do
  stats=`eval ${cmd}`
  nreads=`echo "$stats" | grep 'Reads' | awk '{print $2}'`
  nwrites=`echo "$stats" | grep 'Writes' | awk '{print $2}'`
  nthrottled=`echo "$stats" | grep 'throttled' | awk '{print $3}'`
  nstaggered=`echo "$stats" | grep 'staggered' | awk '{print $3}'`
  nreadsize=`echo "$stats" | grep 'Read\ Size' | awk '{print $4}'`
  nwritesize=`echo "$stats" | grep 'Write\ Size' | awk '{print $4}'`
  nreadwritesize=`echo "$nreadsize + $nwritesize" | bc`

  creads=`echo "$nreads - $preads" | bc`
  cwrites=`echo "$nwrites - $pwrites" | bc`
  cthrottled=`echo "$nthrottled - $pthrottled" | bc`
  cstaggered=`echo "$nstaggered - $pstaggered" | bc`
  creadsize=`echo "$nreadsize - $preadsize" | bc`
  cwritesize=`echo "$nwritesize - $pwritesize" | bc`
 
  iops=`expr $creads + $cwrites`
  creadwritesize=`echo "$nreadwritesize - $preadwritesize" | bc`

  if [ $iops -ge $limit ]; then
    echo `date +%Y:%m:%d,%H:%M:%S`, $creads, $cwrites , $cthrottled, $cstaggered , $creadsize, $cwritesize, $creadwritesize, $iops , Y
  else
    echo `date +%Y:%m:%d,%H:%M:%S`, $creads, $cwrites , $cthrottled, $cstaggered , $creadsize, $cwritesize, $creadwritesize, $iops , N
    #echo `date +%Y%m%d%H%M%S`, $creads, $cwrites , $cthrottled, $cstaggered , $iops , N
  fi

  preads=$nreads
  pwrites=$nwrites
  pthrottled=$nthrottled
  pstaggered=$nstaggered
  preadsize=$nreadsize
  pwritesize=$nwritesize
  preadwritesize=$nreadwritesize

  sleep 1
done
