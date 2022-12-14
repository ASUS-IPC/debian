#!/bin/bash

logfile=$2

do_err_cnt=0
di_err_cnt=0

mode=232
COM1=3
COM2=4
uart_err_cnt=0
baud=9600
COMPORT_TEST="/MCU_test_tool/comport_test"

$COMPORT_TEST -c $COM1 -s 0 > /dev/null 2>&1
$COMPORT_TEST -c $COM1 -s 1 -m $mode -b $baud > /dev/null 2>&1
$COMPORT_TEST -c $COM2 -s 0 > /dev/null 2>&1
$COMPORT_TEST -c $COM2 -s 1 -m $mode -b $baud > /dev/null 2>&1

while [ 1 != 2 ]
do
	/MCU_test_tool/dio_out 3 1 > /dev/null 2>&1
	/MCU_test_tool/dio_out 2 0 > /dev/null 2>&1
	/MCU_test_tool/dio_out 1 1 > /dev/null 2>&1
	/MCU_test_tool/dio_out 0 0 > /dev/null 2>&1
	result=$(/MCU_test_tool/dio_out | grep "1 0 1 0")
	if [[ -n "$result" ]]; then
		echo "MCU DO set 1 0 1 0 Pass" | tee -a $logfile
		do_err_cnt=0
	else
		echo "MCU DO set 1 0 1 0 Fail" | tee -a $logfile
		((do_err_cnt+=1))
	fi

	result=$(/MCU_test_tool/dio_in | grep "1 0 1 0")
	if [[ -n "$result" ]]; then
		echo "MCU DI get 1 0 1 0 Pass" | tee -a $logfile
		di_err_cnt=0
	else
		echo "MCU DI get 1 0 1 0 Fail" | tee -a $logfile
		((di_err_cnt+=1))
	fi
	echo "" | tee -a $logfile
	/MCU_test_tool/dio_out 3 0 > /dev/null 2>&1
	/MCU_test_tool/dio_out 2 1 > /dev/null 2>&1
	/MCU_test_tool/dio_out 1 0 > /dev/null 2>&1
	/MCU_test_tool/dio_out 0 1 > /dev/null 2>&1
	result=$(/MCU_test_tool/dio_out | grep "0 1 0 1")
	if [[ -n "$result" ]]; then
		echo "MCU DO set 0 1 0 1 Pass" | tee -a $logfile
		do_err_cnt=0
	else
		echo "MCU DO set 0 1 0 1 Fail" | tee -a $logfile
		((do_err_cnt+=1))
	fi

	result=$(/MCU_test_tool/dio_in | grep "0 1 0 1")
	if [[ -n "$result" ]]; then
		echo "MCU DI get 0 1 0 1 Pass" | tee -a $logfile
		di_err_cnt=0
	else
		echo "MCU DI get 0 1 0 1 Fail" | tee -a $logfile
		((di_err_cnt+=1))
	fi
	echo "" | tee -a $logfile
	echo "COM3 write" | tee -a $logfile
	$COMPORT_TEST -c $COM1 -w "1234321 " | tee -a $logfile
	sleep 0.1
	result=$($COMPORT_TEST -c $COM2 -r | tee -a $logfile | grep "1234321")
	if [[ -n "$result" ]]; then
		echo "COM4 read Pass" | tee -a $logfile
		uart_err_cnt=0
	else
		echo "COM4 read Fail" | tee -a $logfile
		((uart_err_cnt+=1))
	fi
	echo "" | tee -a $logfile
	echo "COM4 write" | tee -a $logfile
	$COMPORT_TEST -c $COM2 -w "4321234 " | tee -a $logfile
	sleep 0.1
	result=$($COMPORT_TEST -c $COM1 -r | tee -a $logfile | grep "4321234")
	if [[ -n "$result" ]]; then
		echo "COM3 read Pass" | tee -a $logfile
		uart_err_cnt=0
	else
		echo "COM3 read Fail" | tee -a $logfile
		((uart_err_cnt+=1))
	fi
	echo "" | tee -a $logfile
	if [[ $do_err_cnt -ge 5 || $di_err_cnt -ge 5 || $uart_err_cnt -ge 5 ]]; then
		echo "$(date +'%Y%m%d_%H%M') DIO/UART  continue fail over 5 times, do_err_cnt=$do_err_cnt, di_err_cnt=$di_err_cnt, uart_err_cnt=$uart_err_cnt"  | tee -a $logfile
		$COMPORT_TEST -c $COM1 -s 0 > /dev/null 2>&1
		$COMPORT_TEST -c $COM2 -s 0 > /dev/null 2>&1
		exit 1
	fi	
done
