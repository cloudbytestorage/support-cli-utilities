#!/bin/sh
# Usage sh backup_tsm_data.sh

datadir=/tmp/system_hs_logs/`hostname`_system_`date +%d%m%Y_%H%M%S`_tsm_logs
mkdir /tmp/system_hs_logs/ > /dev/null 2>&1
mkdir $datadir > /dev/null 2>&1

top > $datadir/top.out
netstat -nal > $datadir/netstat-overall.out
sockstat > $datadir/sockstat-overall.out
ifconfig > $datadir/ifconfig-overall.out
jls | grep -v JID > $datadir/jail-list.out
jf=$datadir/jail-list.out
 
while read line
do
                echo $line
                i=`echo $line | awk '{print $1}'`
                ip=`echo $line | awk '{print $2}'`
                echo $ip
                jname=`jexec $i hostname`;
                mkdir $datadir/$jname-$ip
                outputdir=$datadir/$jname-$ip
		cp /tenants/$jname/usr/local/etc/istgt/logfile $outputdir/istgt_logfile;
		cp /tenants/$jname/var/log/messages* $outputdir/;
		cp /tenants/$jname/usr/local/etc/istgt/istgt.conf $outputdir/;
		cp /tenants/$jname/usr/local/etc/smb.conf $outputdir/;
		cp /tenants/$jname/etc/exports $outputdir/;
		#jexec $i istgtcontrol info > $outputdir/istgtcontrolinfo;
                jexec $i netstat -nal > $outputdir/netstat.out
		jexec $i sockstat > $outputdir/sockstat.out;
		jexec $i zfs list > $outputdir/zfslist.out;
		vols=`jexec $i zfs list | grep -v "NAME\|tpool" | awk '{print $1}'`;
			if [ -z "${vols}" ]; then
				echo "no volumes found";
			else
				jexec $i istgtcontrol info > $outputdir/istgtinfo.out;
			fi;
	        	for j in $vols;
	         		do
                                    echo "************BEGIN*************" >> $outputdir/rengstats.out;
                                    echo "$j" >> $outputdir/rengstats.out;
                                    echo "------------------------------" >> $outputdir/rengstats.out;
                                    reng stats access dataset $j qos >> $outputdir/rengstats.out;
                                    sleep 1;
                                    reng stats access dataset $j qos >> $outputdir/rengstats.out;
                                    echo "************END*************" >> $outputdir/rengstats.out;
	         		done
done < $jf
echo "Info gathered with this script is located at $datadir"
