#!/bin/sh

backup=$1

if [ $# -lt 1 ]
then
 echo "Usage: sh $0 <backup folder name>"
 exit;
fi

echo "Backup begins please wait it might a minute"
mkdir /root/$backup
folder=/root/$backup
cp -r /cf/conf $folder/
cp /boot/loader.conf $folder/loader.conf
cp /etc/rc.conf $folder/rc.conf
cp /etc/sysctl.conf $folder/sysctl.conf
cp /usr/local/agent/cbc_node_id $folder/cbc_node_id
cp /usr/local/agent/cbd_node_id	$folder/cbd_node_id
cp /usr/local/agent/ipmi.conf $folder/ipmi.conf
ifconfig > $folder/ifconfig.out
zfs list > $folder/zfs-list.out
netstat -an > $folder/netstat_an.out
gmultipath status > $folder/gpath.out
camcontrol devlist > $folder/cam.out
zpool list -v > $folder/zpool_list.out
zpool status -v > $folder/zpool_status.out
zpool iostat 1 10 > $folder/zpool_iostat.out
procstat -kka > $folder/procstat.out
ps -auxHxww -o mwchan,jid,command > $folder/ps.out
top -d5 -s2 -IHjn 100 > $folder/top.out

echo "Node backup available at $folder"
