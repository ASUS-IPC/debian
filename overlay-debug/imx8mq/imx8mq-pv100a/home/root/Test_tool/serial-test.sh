#!/bin/bash
com1to2=0
com2to1=0
logfile="$2/$now"_uart.txt

com1to2=`serial-test -1`
sleep 1
com2to1=`serial-test -2`
if [ "$com1to2" == "1" -a "$com2to1" == "1" ]
then
	echo "PASS" | tee $3 $logfile
else
	echo "FAIL" | tee $3 $logfile
	if [ "$com1to2" == "4" ]
	then
		echo "COM1 write fail" | tee $3 $logfile
		echo "COM2 read fail" | tee $3 $logfile
	elif [ "$com1to2" == "3" ]
	then
		echo "COM1 write fail" | tee $3 $logfile
	elif [ "$com1to2" == "2" ]
	then
		echo "COM2 read fail" | tee $3 $logfile
	fi

	if [ "$com2to1" == "4" ]
	then
		echo "COM2 write fail" | tee $3 $logfile
		echo "COM1 read fail" | tee $3 $logfile
	elif [ "$com2to1" == "3" ]
	then
		echo "COM2 write fail" | tee $3 $logfile
	elif [ "$com2to1" == "2" ]
	then
		echo "COM1 read fail" | tee $3 $logfile
	fi
fi

