#!/bin/sh

# Display the arc statistics for the mos dataset per zpool
# Usage: sh zpool_mos_arc_usage.sh [duration]

#Use 10 seconds as interval between the stats capture.
duration=10
if [ $# -gt 0 ] ; then
  duration=$1
fi

pools=`zpool list | grep -v "NAME" | awk '{print $1}' | xargs`
for pool in $pools
do
  echo "POOL: $pool"
  c_max=`sysctl kstat.zfs.mos_${pool}.arcstats.c_max | awk '{print $2}'`

  pused=`sysctl kstat.zfs.mos_${pool}.arcstats.size | awk '{print $2}'`
  pmisses=`sysctl kstat.zfs.mos_${pool}.arcstats.misses | awk '{print $2}'`
  sleep $duration
  cused=`sysctl kstat.zfs.mos_${pool}.arcstats.size | awk '{print $2}'`
  cmisses=`sysctl kstat.zfs.mos_${pool}.arcstats.misses | awk '{print $2}'`

  pct_used_dec=`echo $pused / $c_max | bc -l`
  pct_used=`echo $pct_used_dec \* 100 | bc -l`
  pct_used_rnd=`printf %.2f "$pct_used"`

  missed=`echo $cmisses - $pmisses | bc -l`

  echo "  Arc Limit  : $c_max"
  echo "  Arc Used   : $pct_used_rnd"
  echo "  Arc Missed : $missed"
done
