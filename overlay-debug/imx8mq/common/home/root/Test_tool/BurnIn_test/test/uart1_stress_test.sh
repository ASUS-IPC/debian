#!/bin/bash
err_cnt=0
SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
logfile=$1
echo "Start UART1 loopback test" | tee -a $logfile
while [ 1 != 2 ]
do
	linux-serial-test -s -e -p /dev/ttymxc0 115200 | tee -a $logfile
	((err_cnt+=1))
	if [[ $err_cnt -ge 3 ]]; then
		exit 1
	fi
	sleep 1
done