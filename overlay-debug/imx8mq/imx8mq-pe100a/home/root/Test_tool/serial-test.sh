#!/bin/bash
com1to2=0
com2to1=0
logfile="$2/$now"_uart.txt

if [ "$1" == "485" ] 
then
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
		echo "RS485 PASS" | tee $3 $logfile
	else
		echo "RS485 FAIL" | tee $3 $logfile
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
elif [ "$1" == "422" ] 
then
	com1to2=`serial-test -1`
	sleep 1
	com2to1=`serial-test -2`
	if [ "$com1to2" == "1" -a "$com2to1" == "1" ]
	then
		echo "RS422 PASS" | tee $3 $logfile
	else
		echo "RS422 FAIL" | tee $3 $logfile
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
elif [ "$1" == "232" ]
then
	#./serial-test
    #COM1 -> COM2
    com1to2=`serial-test -1`
	sleep 1
	#COM2 -> COM1
	com2to1=`serial-test -2`
	
	if [ "$com1to2" == "1" -a "$com2to1" == "1" ]
	then
		echo "RS232 PASS" | tee $3 $logfile
	else
		echo "RS232 FAIL" | tee $3 $logfile
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
else
	echo "Please enter testing standard."
fi

