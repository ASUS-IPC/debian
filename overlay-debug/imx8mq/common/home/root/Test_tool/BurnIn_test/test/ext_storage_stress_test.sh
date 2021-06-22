#!/bin/bash
TAG=$1
udev=$1
logfile=$2
cnt=0
pass_cnt=0
err_cnt=0
rm_err_cnt=0
fifoStr="01234567890abcdefghijklmnopqrstuvwxyz!@#$%^&*()"

log()
{
	echo "$(date +'%Y%m%d_%H.%M.%S') $TAG $@"  | tee -a $logfile
}

get_mount_point()
{
	#Check external storage mounut or not
	mount_point=$(cat /proc/mounts | grep $udev | awk '{print $2}')
	mount_point=$(echo $mount_point | awk '{print $1}')

	echo mount_point = $mount_point

	if [ -z $mount_point ]; then
		usb_blk=$(cat /proc/partitions | grep $udev | awk '{print $4}')
		if [ -z $usb_blk ]; then
			log "USB storage not detect, exit test!!"
			exit
		else
			log "USB storage detect but not mounted"
			log "File manager format not supported"
			log "Please manually format external storage to FAT32, exit test!!"
			exit
		fi
	fi

	tmpfile=/$mount_point/tmpfile
}

get_mount_point
echo "tmpfile=$tmpfile"

while [ 1 != 2 ]
do
	cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
	cpu_temp=`awk 'BEGIN{printf "%.2f\n",('$cpu_temp'/1000)}'`

	# Remove testfile
	if [ -e ${tmpfile} ]; then
		rm ${tmpfile} > /dev/null 2>&1
		if [[ $? -ne 0 ]]; then
			((rm_err_cnt+=1))
			log "Read/Write: fail , can't remove ${tmpfile}, cpu temp=$cpu_temp"
		else
			rm_err_cnt=0
		fi	
	fi
	sleep 1

	# Read/Write testfile
	echo $fifoStr > $tmpfile
	ReadStr=`cat $tmpfile`
	if [ $fifoStr == $ReadStr ]; then
		status="pass"
		((pass_cnt+=1))
	else
		status="fail"
		((err_cnt+=1))
	fi
	log "Read/Write: $status , pass_cnt=$pass_cnt, err_cnt=$err_cnt, cpu temp=$cpu_temp"
done
