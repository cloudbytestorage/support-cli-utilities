# This Script can be used to upgrade the SanDisk Firmware Upgrade 
if [ $# -eq 0 ]; then
echo "Error : Argument is not there"
echo "Please give argument as firmware binary name"
echo "eg :sh SandiskFwUpgradeGenerate.sh optimus_eco_ex2_generic_K0A0_800GB_fw_plus_boot.dob"
exit
fi 
name=$1
ls -l $name > /dev/null
if [ $? = 1 ]; then
echo "Copy binary file to this directory"
exit
fi

size=`ls -l $name | awk '{ print $5 }'`
filename="FwUpgr_${name}.sh"
>$filename



length=8192
offset=0
y=$(expr $size / $length)
x=1
n=`expr $y - $x`
echo "if [ \$# -eq 0 ]; then" >> $filename
echo "echo \"Error : Argument is not there.. Please run the script as below:\"" >> $filename
echo "echo \"sh optimus_eco_ex2_generic_K0A0_800GB_fw_plus_boot.dob.sh da3\"" >> $filename
echo "exit" >> $filename
echo "fi" >> $filename
echo "disk=\$1" >> $filename
echo "sg_write_buffer --id=0 --in=$name --mode=0x7 --specific=0 --offset=$offset --length=$length -vvvv \$disk" >> $filename

for i in $(seq 1 $n); 
do
offset=`expr $offset + $length`
skip=$offset
echo "sg_write_buffer --id=0 --in=$name --mode=0x7 --specific=0 --offset=$offset --skip=$skip --length=$length -vvvv \$disk" >> $filename

done
lastoffset=`expr $offset + $length`
lastskip=$lastoffset
lastlength=`expr $size - $lastoffset`
echo "sg_write_buffer --id=0 --in=$name --mode=0x7 --specific=0 --offset=$lastoffset --skip=$lastskip --length=$lastlength -vvvv \$disk" >> $filename

echo ""
echo "Please run $filename with disk da number as argument"
echo "eg : sh $filename da6" 
echo ""
echo "Do a camcontrol rescan all"
echo "Check new version on camcontrol devlist"

