#!/bin/sh
##This script will check IP are assign after HA 
#Usages:sh checkip_ha.sh <giveback/takeover>
if [ $# -lt 1 ]
then
 echo "Usages: $0 <giveback/takeover>"
 exit;
fi
status=$1
timestamp=$(date +"%d%h%y_%H%M")
FILE="IPs_Check$timestamp"
mkdir $FILE 
cp /cf/conf/config.xml $FILE 
cp /cf/conf/peerconfig*.xml $FILE  
ifconfig > $FILE/ifconfig.out
jls > $FILE/jls.out
cd $FILE
grep "ipaddress" config.xml | cut -d ">" -f 2 | cut -d "<" -f 1 |awk '{print $1}'|sed '1d' >config.out
grep -A 2 "<bkpnetwork>" config.xml | grep "<ip>" | cut -d ">" -f 2 | cut -d "<" -f 1 |awk '{print $1}' > backup_ip_config.out
grep -A 2 "<bkpnetwork>" config.xml | grep "<ip>" | cut -d ">" -f 2 | cut -d "<" -f 1 |awk '{print $1}' >>config.out 
grep "ipaddress" config.xml | cut -d ">" -f 2 | cut -d "<" -f 1 |awk '{print $1}'|sed '1d' >config_peerconfig.out
grep "ipaddress" peerconfig*.xml | cut -d ">" -f 2 | cut -d "<" -f 1 |awk '{print $1}'|sed '1d'>>config_peerconfig.out
grep -A 2 "<bkpnetwork>" peerconfig*.xml | grep "<ip>" | cut -d ">" -f 2 | cut -d "<" -f 1 |awk '{print $1}' > backup_ip_peerconfig.out
grep -A 2 "<bkpnetwork>" peerconfig*.xml | grep "<ip>" | cut -d ">" -f 2 | cut -d "<" -f 1 |awk '{print $1}' >> config_peerconfig.out 
awk '{ print $2 }' jls.out | grep -v IP >jail_ips.out
echo "All IPs in ifconfig are collected inside IPs  directory with file name if.out"
grep "inet" ifconfig.out | awk '{print $2}' >if.out
while read line
do
   grep "$line" if.out >>beforeha.out
done < config.out
if [ $status = "giveback" ]
 then
echo "These are the Jail IP,backup_ips & output is inside IPs directory with file name beforeha.out \n"
 cat beforeha.out
echo "These are the backup ip from current node, if you are not seeing any output then it means no backup ip is configure " 
 cat backup_ip_config.out
egrep "`cat jail_ips.out |xargs -I {} echo -n '|{}'|sed -e 's/^|//'`" beforeha.out > matching_ips.out
echo "These Ips are assingened in ifconfig,config.xml and jail"
cat matching_ips.out 
 echo "Files are located at "$FILE 
 exit
fi

if [ $status = "takeover" ]
 then
##egrep -v "`cat l1 |xargs -I {} echo -n '|{}'|sed -e 's/^|//'`" l2 (this is the command to print l2 files)(if we remove -v it will present the ips present in both l1 and l2 file)
#Ips present in if.out and config_peerconfig
 egrep  "`cat if.out|xargs -I {} echo -n '|{}'|sed -e 's/^|//'`" config_peerconfig.out >afterha_matching.out
 egrep -v "`cat if.out|xargs -I {} echo -n '|{}'|sed -e 's/^|//'`" config_peerconfig.out >afterha.out
 echo "These are the IPs which are not assigned and output is inside IPs directory,if you are not seeing any IP then it means all IP are assigned"
 cat afterha.out
 echo " These are the backup ip of peernode,if you are not seeing any output then it means no backup ip is configure  "
 cat backup_ip_peerconfig.out
egrep "`cat jail_ips.out |xargs -I {} echo -n '|{}'|sed -e 's/^|//'`" afterha_matching.out >A_matching_ips.out
echo "These Ips are assingened in ifconfig,config.xml,peerconfig.xml and jail"
cat A_matching_ips.out
 echo "Files are located at "$FILE 
 exit
fi 


