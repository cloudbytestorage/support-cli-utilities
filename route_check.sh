#!/bin/sh

# To check the routes are fine and sending mail alert if any routes are deleted
folder=/root/support
cd $folder
backup=10.1.44.0/22
gd=10.1.60.0/24
flag=0
while true; do
  netstat -rnW | grep -i 10.1.57.1> netstat_rnW_script.out
  countbackup=$(grep "$backup" netstat_rnW_script.out|wc -l)
  countgd=$(grep "$gd" netstat_rnW_script.out|wc -l)
  if [$countbackup -eq $flag ]
  then
    #/sbin/route add -net 10.1.44.0/22 10.1.57.1
    cat BackupAlert.out | mail -s "`hostname` Route check alert" -F ranjith.raveendran@cloudbyte.com
  fi
  if [$countgd -eq $flag ]
  then
    #/sbin/route add -net 10.1.60.0/24 10.1.57.1
    cat GDAlert.out | mail -s "`hostname` Route check alert" -F ranjith.raveendran@cloudbyte.com
  fi
  sleep 60
done
