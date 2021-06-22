#!/bin/bash
times=0
rm_err_cnt=0
cp_err_cnt=0
logfile=$2

mSATA_blk=0

# Check mSATA blk exist
sd_blk=$(cat /proc/partitions | grep sd | awk '{print $4}')
if [ -z $sd_blk ]; then
	echo mSATA card not detect, exit test!! | tee -a $logfile
	exit
fi

for blk in $sd_blk
do
	blk=${blk:0:3}
	blk_removable=$(cat /sys/block/$blk/removable)
	if [ $blk_removable == "0" ];then
		echo disk $blk was not removable, it is sata devices
		mSATA_blk=$blk
		break
	fi
done

if [ $mSATA_blk == "0" ];then
	echo No mSATA card detected, exit test!! | tee -a $logfile
	exit
fi

echo mSATA_blk = $mSATA_blk  | tee -a $logfile

# Get mSATA mount point
mSATA_mp=$(cat /proc/mounts | grep "/dev/${mSATA_blk}" | awk '{print $2}')
mSATA_mp=$(echo $mSATA_mp | awk '{print $1}')
if [ -z $mSATA_mp ]; then
	echo mSATA card detect but not mounted | tee -a $logfile
	echo File manager format not supported | tee -a $logfile
	echo Please manually format mSATA to FAT32, exit test!! | tee -a $logfile
	exit
fi
echo mSATA mount point = $mSATA_mp  | tee -a $logfile
tmpfile=/$mSATA_mp/tmpfile

while [ 1 != 2 ]
do
	cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
	cpu_temp=`awk 'BEGIN{printf "%.2f\n",('$cpu_temp'/1000)}'`

	# Remove testfile
	if [ -e ${tmpfile} ]; then
		rm ${tmpfile} > /dev/null 2>&1
		if [[ $? -ne 0 ]]; then
			((rm_err_cnt+=1))
		else
			rm_err_cnt=0
		fi
	fi
	sleep 1

	# Write testfile
	dd if=/dev/zero of=${tmpfile} bs=1M count=5 conv=fdatasync > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		((w_err_cnt+=1))
	else
		w_err_cnt=0
	fi 
	sleep 1

	#Read testfile
	dd if=${tmpfile} of=/dev/null bs=1M count=5 > /dev/null 2>&1
 	if [[ $? -ne 0 ]]; then
		((r_err_cnt+=1))
	else
		r_err_cnt=0
		((times+=1))
		echo "$(date +'%Y%m%d_%H%M') mSATA test pass $times times, cpu temp = $cpu_temp" | tee -a $logfile
	fi 
	sleep 1

	if [[ $w_err_cnt -ge 5 || $r_err_cnt -ge 5 || $rm_err_cnt -ge 5 ]]; then
		echo "$(date +'%Y%m%d_%H%M') mSATA test continue fail over 5 times, w_err_cnt=$w_err_cnt, r_err_cnt=$r_err_cnt, rm_err_cnt=$rm_err_cnt"  | tee -a $logfile
		exit 1
	fi
done


