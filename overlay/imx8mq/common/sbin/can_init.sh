#!/bin/sh

function enable_can()
{
	iface="$1"
	counter=0
	echo "$iface"
	while [ $counter -le 3 ]
	do
		/sbin/ip link set $iface up type can bitrate 125000
		check_val=$( /sbin/ifconfig -s | grep "$iface" )
		if [ ! -z "$check_val" ]; then
			echo "$iface is up!"
			return
		fi
		echo "$iface is up fail, rety again"
		counter=`expr $counter + 1`
	done
	echo "$iface is up fail over 3 times"
}

if [ ! -z $( ls /sys/class/net | grep can0 ) ]; then
	echo "enable can0"
	enable_can "can0"
fi

if [ ! -z $( ls /sys/class/net | grep can1 ) ]; then
	echo "enable can1"
	enable_can "can1"
fi


