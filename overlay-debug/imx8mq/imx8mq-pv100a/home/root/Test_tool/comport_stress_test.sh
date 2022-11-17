#!/bin/bash

now="$(date +'%Y%m%d_%H%M')"
logfile="$1/$now"_mcu_uart.txt
tmpfile=$1/com1_com2_tmp.txt
COMPORT_TEST="/MCU_test_tool/comport_test"
uart_err_cnt=0
baud=9600
str1=12345678
str2=87654321
err_cnt_12=0
err_cnt_21=0
i=0

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
	$COMPORT_TEST -c $COM1 -s 0 > /dev/null 2>&1
	$COMPORT_TEST -c $COM1 -s 1 -m $mode -b $baud > /dev/null 2>&1
fi

if [ "$COM2" == "3" ] || [ "$COM2" == "4" ]; then
	$COMPORT_TEST -c $COM2 -s 0 > /dev/null 2>&1
	$COMPORT_TEST -c $COM2 -s 1 -m $mode -b $baud > /dev/null 2>&1
fi

if [ "$COM1" == "1" ]; then
	COM1PORT=/dev/ttymxc0
elif [ "$COM1" == "2" ]; then
	COM1PORT=/dev/ttymxc1
fi

if [ "$COM2" == "1" ]; then
	COM2PORT=/dev/ttymxc0
elif [ "$COM2" == "2" ]; then
	COM2PORT=/dev/ttymxc1
fi

if [ $COM1PORT ]; then
	serial-setup -c $COM1PORT -b $baud
fi

if [ $COM2PORT ]; then
	serial-setup -c $COM2PORT -b $baud
fi

while [ 1 != 2 ]
do
	echo "=========== $i loop ============="

	if [ "$COM1" == "1" ] && [ "$COM2" == "2" ]; then	# SoC to SoC
		# COM1 -> COM2
		cat $COM2PORT > $tmpfile &
		sleep 0.1
		echo -e "$str1" > $COM1PORT
		sleep 0.6
		pid=$(ps -aux | grep $COM2PORT | grep -v grep | awk '{print $2}')
		kill -9 $pid
		result=$(cat $tmpfile | tee -a $logfile | grep $str1 )
		rm $tmpfile
		if [[ -n "$result" ]]; then
			echo "COM$COM1 -> COM$COM2 Pass" | tee $2 $logfile
			err_cnt_12=0
		else
			((err_cnt_12+=1))
			echo "COM$COM1 -> COM$COM2 Fail, err_cnt_12=${err_cnt_12}" | tee $2 $logfile

		fi

		# COM2 -> COM1
		cat $COM1PORT > $tmpfile &
		sleep 0.1
		echo -e "$str2" > $COM2PORT
		sleep 0.5
		pid=$(ps -aux | grep $COM1PORT | grep -v grep | awk '{print $2}')
		kill -9 $pid
		result=$(cat $tmpfile | tee -a $logfile | grep $str2 )
		rm $tmpfile
		if [[ -n "$result" ]]; then
			echo "COM$COM2 -> COM$COM1 Pass" | tee $2 $logfile
			err_cnt_21=0
		else
			((err_cnt_21+=1))
			echo "COM$COM2 -> COM$COM1 Fail, err_cnt_21=${err_cnt_21}" | tee $2 $logfile
		fi

	elif [ "$COM1" == "3" ] && [ "$COM2" == "4" ]; then	# MCU to MCU
		# COM1 -> COM2
		$COMPORT_TEST -c $COM1 -w $str1 > /dev/null 2>&1
		sleep 0.5
		result=$($COMPORT_TEST -c $COM2 -r | grep $str1)
		if [[ -n "$result" ]]; then
			echo "COM$COM1 -> COM$COM2 Pass" | tee $2 $logfile
			err_cnt_12=0
		else
			((err_cnt_12+=1))
			echo "COM$COM1 -> COM$COM2 Fail, err_cnt_12=${err_cnt_12}" | tee $2 $logfile
		fi

		# COM2 -> COM1
		$COMPORT_TEST -c $COM2 -w $str2 > /dev/null 2>&1
		sleep 0.5
		result=$($COMPORT_TEST -c $COM1 -r | grep $str2)
		if [[ -n "$result" ]]; then
			echo "COM$COM2 -> COM$COM1 Pass" | tee $2 $logfile
			err_cnt_21=0
		else
			((err_cnt_21+=1))
			echo "COM$COM2 -> COM$COM1 Fail, err_cnt_21=${err_cnt_21}" | tee $2 $logfile
		fi

	else							# SoC to MCU
		# COM1 -> COM2
		$COMPORT_TEST -c $COM2 -R > $tmpfile &
		sleep 0.1
		echo -e "$str1" > $COM1PORT
		sleep 0.5
		pid=$(ps -aux | grep "comport_test -c $COM2 -R" | grep -v grep | awk '{print $2}')
		kill -9 $pid
		result=$(cat $tmpfile | tee -a $logfile | grep $str1 )
		rm $tmpfile
		if [[ -n "$result" ]]; then
			echo "COM$COM1 -> COM$COM2 Pass" | tee $2 $logfile
			err_cnt_12=0
		else
			((err_cnt_12+=1))
			echo "COM$COM1 -> COM$COM2 Fail, err_cnt_12=${err_cnt_12}" | tee $2 $logfile
		fi

		# COM2 -> COM1
		cat $COM1PORT > $tmpfile &
		sleep 0.1
		$COMPORT_TEST -c $COM2 -w $str2 > /dev/null 2>&1
		sleep 0.5
		pid=$(ps -aux | grep $COM1PORT | grep -v grep | awk '{print $2}')
		kill -9 $pid
		result=$(cat $tmpfile | tee -a $logfile | grep $str2 )
		if [[ -n "$result" ]]; then
			echo "COM$COM2 -> COM$COM1 Pass" | tee $2 $logfile
			err_cnt_21=0
		else
			((err_cnt_21+=1))
			echo "COM$COM2 -> COM$COM1 Fail, err_cnt_21=${err_cnt_21}" | tee $2 $logfile
		fi
	fi

	if [[ ${err_cnt_12} -eq 3 || ${err_cnt_21} -eq 3 ]]; then
		sleep 3
	fi

	if [[ ${err_cnt_12} -ge 5 || ${err_cnt_21} -ge 5 ]]; then
		echo "COM$COM1 <-> COM$COM2 continue fail over 5 times, err_cnt_12=${err_cnt_12}, err_cnt_21=${err_cnt_21}" | tee $2 $logfile
		exit 1
	fi
	sleep 0.1
	((i+=1))
done

