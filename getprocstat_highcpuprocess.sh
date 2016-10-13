filename=`hostname`__`date +%s`.out
top -d1 -s2 -IHjn 100 > $filename
PID="$(head -10 $filename | awk '{print $1}' | tail -1)"
echo -e "$PID"
procstat -kk $PID > procstat.out
