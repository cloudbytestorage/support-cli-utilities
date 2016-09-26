#!/bin/sh
## This script gets detail about VSM health
#usage= {sh vsm_health_check.sh <vsmip>}
if [ $# -lt 1 ]
then
 echo "Enter the VSM IP";
 echo "Usage:sh vsm_health_check.sh <vsmip>"
 exit;
fi
timestamp=$(date +"%d-%m-%Y")
FILE=/root/"VSM_Health_$timestamp"
mkdir -p $FILE
cd $FILE
echo "Detailed outuput in /root/"VSM_Health_$timestamp
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BLACK='\033[0;30m'
NC='\033[0m'
jip="$1"
echo -e "${RED}Jail IP:${NC}$jip\n"

jlsipbind=`/sbin/ifconfig |grep -c "$jip"`
/sbin/ifconfig | grep -B 3 "$jip" > jlsifconfig.out
if [ $jlsipbind -eq 0 ]
then
 echo -e "$jip is not binded\n"
else
 echo -e "$jip is binded\n"
fi

jlsid="$(jls | grep "$jip"|awk '{printf "%s", $1}')"
jlspath="$(jls | grep "$jip"|awk '{printf "%s", $4}')"
echo -e "${RED}Jail Id:${NC}$jlsid\n"
echo -e "${RED}Jail path:${NC}$jlspath\n"
echo -e "${RED}zfs list of this  VSM are:${NC}\n"
jexeccmd="$(jexec $jlsid zfs list|grep -v tpool)"
echo -e "$jexeccmd\n"

echo -e "${BLUE}NFS Details${NC}\n"
jlsexport="$(jexec  $jlsid cat /etc/export)" 
echo "$jlsexport" > export.out  2>&1
echo -e "${CYAN}Services running status:${NC}\n"
jlslockd="$(jexec $jlsid service lockd onestatus)"
jlsmountd="$(jexec $jlsid service mountd onestatus)"
jlsstatd="$(jexec $jlsid service statd  onestatus)"
jlsrpcbind="$(jexec $jlsid service rpcbind onestatus)"
jlsnfsd="$(jexec $jlsid service nfsd onestatus)"
echo -e "$jlslockd\n$jlsmountd\n$jlsstatd\n$jlsrpcbind\n$jlsnfsd\n"

echo -e "${BLUE}iSCSI details${NC}\n"
echo -e "${CYAN}Services running status:${NC}\n"
jlsiscsi="$(jexec $jlsid service istgt onestatus)"
echo -e "$jlsiscsi\n"

jlsistgt="$(jexec $jlsid istgtcontrol dump)"
echo  "$jlsistgt" > istgtcontrol_dump.out
jlsnetstat="$(jexec "$jlsid" netstat -an | grep -i est | grep "3260\|2049\|445")"
echo "$jlsnetstat" > clientconnected.out
