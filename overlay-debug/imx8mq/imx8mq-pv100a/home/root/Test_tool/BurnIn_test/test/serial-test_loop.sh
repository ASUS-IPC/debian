#!/bin/bash
com1to2=0
com2to1=0
logfile=$3

com1to2_err_cnt=0
com2to1_err_cnt=0

if [ "$1" == "485" ] 
then
	while [ 1 != 2 ]
	do
	echo "157" > /sys/class/gpio/export
	echo "out" > /sys/class/gpio/gpio157/direction
	echo "1" > /sys/class/gpio/gpio157/value
	#COM1 -> COM2
	com1to2=`serial-test -1`
	sleep 1
	echo "0" > /sys/class/gpio/gpio157/value
	#COM2 -> COM1
	com2to1=`serial-test -2`
	echo "157" > /sys/class/gpio/unexport
	
	if [ "$com1to2" == "1" -a "$com2to1" == "1" ]
	then
		echo "RS485 PASS" | tee -a $logfile
		com1to2_err_cnt=0
		com2to1_err_cnt=0
	else
		echo "RS485 FAIL" | tee -a $logfile
		if [ "$com1to2" == "4" ]
		then
			echo "COM1 write fail" | tee -a $logfile
			echo "COM2 read fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		elif [ "$com1to2" == "3" ]
		then
			echo "COM1 write fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		elif [ "$com1to2" == "2" ]
		then
			echo "COM2 read fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		fi

		if [ "$com2to1" == "4" ]
		then
			echo "COM2 write fail" | tee -a $logfile
			echo "COM1 read fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		elif [ "$com2to1" == "3" ]
		then
			echo "COM2 write fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		elif [ "$com2to1" == "2" ]
		then
			echo "COM1 read fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		fi
	fi

	if [[ $com1to2_err_cnt -ge 5 || $com2to1_err_cnt -ge 5 ]]; then
		echo "$(date +'%Y%m%d_%H%M') uart test continue fail over 5 times, com1to2_err_cnt=$com1to2_err_cnt, com2to1_err_cnt=$com2to1_err_cnt"  | tee -a $logfile
		exit 1
	fi

	done
elif [ "$1" == "422" ] 
then
	while [ 1 != 2 ]
	do
	com1to2=`serial-test -1`
	sleep 1
	com2to1=`serial-test -2`
	if [ "$com1to2" == "1" -a "$com2to1" == "1" ]
	then
		echo "RS422 PASS" | tee -a $logfile
		com1to2_err_cnt=0
		com2to1_err_cnt=0
	else
		echo "RS422 FAIL" | tee -a $logfile
		if [ "$com1to2" == "4" ]
		then
			echo "COM1 write fail" | tee -a $logfile
			echo "COM2 read fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		elif [ "$com1to2" == "3" ]
		then
			echo "COM1 write fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		elif [ "$com1to2" == "2" ]
		then
			echo "COM2 read fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		fi

		if [ "$com2to1" == "4" ]
		then
			echo "COM2 write fail" | tee -a $logfile
			echo "COM1 read fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		elif [ "$com2to1" == "3" ]
		then
			echo "COM2 write fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		elif [ "$com2to1" == "2" ]
		then
			echo "COM1 read fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		fi
	fi

	if [[ $com1to2_err_cnt -ge 5 || $com2to1_err_cnt -ge 5 ]]; then
		echo "$(date +'%Y%m%d_%H%M') uart test continue fail over 5 times, com1to2_err_cnt=$com1to2_err_cnt, com2to1_err_cnt=$com2to1_err_cnt"  | tee -a $logfile
		exit 1
	fi

	done
elif [ "$1" == "232" ]
then
	while [ 1 != 2 ]
	do
	#./serial-test
    #COM1 -> COM2
    com1to2=`serial-test -1`
	sleep 1
	#COM2 -> COM1
	com2to1=`serial-test -2`
	
	if [ "$com1to2" == "1" -a "$com2to1" == "1" ]
	then
		echo "RS232 PASS" | tee -a $logfile
		com1to2_err_cnt=0
		com2to1_err_cnt=0
	else
		echo "RS232 FAIL" | tee -a $logfile
		if [ "$com1to2" == "4" ]
		then
			echo "COM1 write fail" | tee -a $logfile
			echo "COM2 read fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		elif [ "$com1to2" == "3" ]
		then
			echo "COM1 write fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		elif [ "$com1to2" == "2" ]
		then
			echo "COM2 read fail" | tee -a $logfile
			((com1to2_err_cnt+=1))
		fi

		if [ "$com2to1" == "4" ]
		then
			echo "COM2 write fail" | tee -a $logfile
			echo "COM1 read fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		elif [ "$com2to1" == "3" ]
		then
			echo "COM2 write fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		elif [ "$com2to1" == "2" ]
		then
			echo "COM1 read fail" | tee -a $logfile
			((com2to1_err_cnt+=1))
		fi
	fi

	if [[ $com1to2_err_cnt -ge 5 || $com2to1_err_cnt -ge 5 ]]; then
		echo "$(date +'%Y%m%d_%H%M') uart test continue fail over 5 times, com1to2_err_cnt=$com1to2_err_cnt, com2to1_err_cnt=$com2to1_err_cnt"  | tee -a $logfile
		exit 1
	fi

	done
else
	echo "Please enter testing standard."
fi

