#!/bin/bash

RESULT=/var/log/system_test/result
LOG=/var/log/system_test/exist_io
USB=/var/log/system_test/exist_usb
TMP_USB=/var/log/system_test/tmp_usb
PCI=/var/log/system_test/exist_pci
TMP_PCI=/var/log/system_test/tmp_pci
exist_io=`cat $LOG`

rm -rf $RESULT

check_cpu()
{
	result=`nproc`
	if [ "$1" = "$result" ]; then
		echo "Pass, cpu core number correct ($result)" | tee -a $RESULT
	else
		echo "Fail, cpu core number error ($result)" | tee -a $RESULT
	fi
}

check_ddr()
{
	result=`free | grep Mem | awk '{print $2}'`
	if [ "$1" = "$result" ]; then
		echo "Pass, ddr size correct ($result)" | tee -a $RESULT
	else
		echo "Fail, ddr size error ($result)" | tee -a $RESULT
	fi
}

check_iface()
{
	result=`ifconfig | grep $1`

	if [ -n "$result" ]; then
		echo "Pass, $1 exist" | tee -a $RESULT
	else
		echo "Fail, $1 not exist" | tee -a $RESULT
	fi
}

check_blk()
{
	if [ "$1" == emmc ]; then
		result=`lsblk | grep mmcblk0`

	elif [ "$1" == sd ]; then
		result=`lsblk | grep mmcblk1`
	fi

	if [ -n "$result" ]; then
		echo "Pass, $1 exist" | tee -a $RESULT
	else
		echo "Fail, $1 not exist" | tee -a $RESULT
	fi
}

check_usb()
{
	result=`lsusb | awk '{print $6}' | sudo tee $TMP_USB`
	if [ -n "$result" ]; then
		usb_cnt=`cat $USB | wc -l`
		tmp_usb_cnt=`cat $TMP_USB | wc -l`
		echo "usb_cnt=$usb_cnt, tmp_usb_cnt=$tmp_usb_cnt"
		if [ "$usb_cnt" != "$tmp_usb_cnt" ]; then
			echo "Fail, lose usb device" | tee -a $RESULT
		fi

		for sub_usb in `cat $TMP_USB`
		do
			usb_flag=$( cat $USB | grep "$sub_usb" | grep -v "grep")
			if [ "$usb_flag" == ""  ]
			then
				echo "Fail, usb device $sub_usb not found! " | tee -a $RESULT
			else
				echo "Pass, usb device $sub_usb found" | tee -a $RESULT
			fi
		done
	fi
}

check_pci()
{
	result=`lspci | sudo tee $TMP_PCI`
	if [ -n "$result" ]; then
		if diff "$PCI" "$TMP_PCI"; then
			echo "Pass, all pci device exist" | tee -a $RESULT
		else
			echo "Fail, lose pci device" | tee -a $RESULT
		fi
	fi
}

check_mcu()
{
	result=`system_test | grep version | awk '{print $5}'`
	if [ "$1" = "$result" ]; then
		echo "Pass, get mcu ver successfully ($result)" | tee -a $RESULT
	else
		echo "Fail, get wrong mcu ver ($result)" | tee -a $RESULT
	fi
}

for io in $exist_io
do

	if [ "$find_cpu" == 1 ]; then
		find_cpu=0
		check_cpu $io
	fi

	if [ "$find_ddr" == 1 ]; then
		find_ddr=0
		check_ddr $io
	fi

	if [ "$find_mcu" == 1 ]; then
		find_mcu=0
		check_mcu $io
	fi

	if [ "$io" == eth0 -o "$io" == eth1 -o "$io" == wlan0 -o "$io" == can0 -o "$io" == can1 ]; then
		check_iface $io
	elif [ "$io" == sd -o "$io" == emmc ]; then
		check_blk $io
	elif [ "$io" == usb ]; then
		check_usb $io
	elif [ "$io" == pci ]; then
		check_pci $io
	elif [ "$io" == cpu ]; then
		find_cpu=1
	elif [ "$io" == ddr ]; then
		find_ddr=1
	elif [ "$io" == mcu ]; then
		find_mcu=1
	fi

done

