#!/bin/bash


mem_above_2G=$((3*1024*1024))
swap_size=$((2*1024*1024))


echo "mem_above_2G=$mem_above_2G  swap_size=$swap_size"

total_mem=$(free | grep Mem | awk '{print $2}')
if [ "$total_mem" -lt "$mem_above_2G" ]; then
	echo "total memory <= 2G"
else
	echo "total memory > 2G"
	exit
fi

swap_file_size=0
if [ -f "/swap" ]; then
	swap_file_size=$(du /swap | awk '{print $1}')
	echo "/swap exist, swap_file_size=$swap_file_size"
else
	swap_file_size=0
	echo "there is no /swap"
fi

if [ "$swap_file_size" -lt "$swap_size" ]; then
	swapoff /swap
	rm -rf /swap
	dd if=/dev/zero of=/swap bs=1024 count=$swap_size
        mkswap /swap
	swapon /swap
	echo "create /swap"
	#echo "/swap swap swap defaluts 0 0" >> /etc/fstab
else
        swapon /swap
	echo "valid swap file already exist"
fi

fstab_swap=$(cat /etc/fstab | grep /swap)

if [ -n "$fstab_swap" ]; then
	echo "/etc/fstab has /swap"
else
	echo "/etc/fstab has no /swap"
	echo "/swap swap swap defaluts 0 0" >> /etc/fstab
fi
