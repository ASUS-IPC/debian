#!/bin/bash

now="$(date +'%Y%m%d_%H%M')"
logfile="$1/$now"_mcu_uart.txt

uart_err_cnt=0

select_test_item()
{
	echo "============================================"
	echo
	echo                "PE101A UART Test"
	echo
	echo "============================================"
	echo
	echo "1. COM1 <-> COM2"
	echo "2. COM1 <-> COM3"
	echo "3. COM1 <-> COM4"
	echo "4. COM2 <-> COM3"
	echo "5. COM2 <-> COM4"
	echo "6. COM3 <-> COM4"
	read -p "Select test case: " test_item
}

select_uart_mode()
{
	echo ""
	read -p  "Enter COM mode(232/422/485) : " mode
}

select_rs485_mode()
{
	echo ""
	echo "1. DE#"
	echo "2. RE#"
	read -p  "Select RS485 mode : " rs485_mode
}

select_test_item
select_uart_mode
#if [ "$mode" == "485" ]; then
#	select_rs485_mode
#fi
rs485_mode=2

case $test_item in
	1)	COM1=1
		COM2=2
		;;
	2)	COM1=1
		COM2=3
		;;
	3)	COM1=1
		COM2=4
		;;
	4)	COM1=2
		COM2=3
		;;
	5)	COM1=2
		COM2=4
		;;
	6)	COM1=3
		COM2=4
		;;
esac

ex_gpio -c $COM1 $mode > /dev/null 2>&1
ex_gpio -c $COM2 $mode > /dev/null 2>&1

if [ "$COM1" == "3" ] || [ "$COM1" == "4" ]; then
	comport_test_pv100a -c $COM1 -s 0 > /dev/null 2>&1
	comport_test_pv100a -c $COM1 -s 1 -m $mode > /dev/null 2>&1
fi

if [ "$COM2" == "3" ] || [ "$COM2" == "4" ]; then
	comport_test_pv100a -c $COM2 -s 0 > /dev/null 2>&1
	comport_test_pv100a -c $COM2 -s 1 -m $mode > /dev/null 2>&1
fi

if [ "$mode" == "485" ]; then
	echo "155" > /sys/class/gpio/export
	echo "out" > /sys/class/gpio/gpio155/direction
fi

while [ 1 != 2 ]
do
	if [ "$mode" == "485" ] && [ "$COM1" == "1" ]; then
		if [ "$rs485_mode" == "1" ]; then #DE
			echo "0" > /sys/class/gpio/gpio155/value
		else #RE
			echo "1" > /sys/class/gpio/gpio155/value
		fi
	fi

	echo "COM$COM1 write" | tee $2 $logfile
	comport_test_pv100a -c $COM1 -w "1234321 " > /dev/null 2>&1 &
	sleep 0.1
	result=$(comport_test_pv100a -c $COM2 -r | grep "1234321")
	if [[ -n "$result" ]]; then
		echo "COM$COM2 read Pass" | tee $2 $logfile
		uart_err_cnt=0
	else
		echo "COM$COM2 read Fail" | tee $2 $logfile
		((uart_err_cnt+=1))
	fi
	echo "" | tee $2 $logfile

######################################################################

	if [ "$mode" == "485" ] && [ "$COM1" == "1" ]; then
		if [ "$rs485_mode" == "1" ]; then #DE
			echo "1" > /sys/class/gpio/gpio155/value
		else #RE
			echo "0" > /sys/class/gpio/gpio155/value
		fi
	fi

	echo "COM$COM2 write" | tee $2 $logfile
	comport_test_pv100a -c $COM2 -w "4321234 " > /dev/null 2>&1 &
	sleep 0.1
	result=$(comport_test_pv100a -c $COM1 -r | grep "4321234")
	if [[ -n "$result" ]]; then
		echo "COM$COM1 read Pass" | tee $2 $logfile
		uart_err_cnt=0
	else
		echo "COM$COM1 read Fail" | tee $2 $logfile
		((uart_err_cnt+=1))
	fi
	echo "" | tee $2 $logfile
	if [[ $uart_err_cnt -ge 5 ]]; then
		echo "$(date +'%Y%m%d_%H%M') UART continue fail over 5 times, uart_err_cnt=$uart_err_cnt" | tee $2 $logfile
		comport_test_pv100a -s 0 > /dev/null 2>&1
		exit 1
	fi
done

