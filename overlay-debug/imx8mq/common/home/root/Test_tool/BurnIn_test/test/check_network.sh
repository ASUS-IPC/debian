#!/bin/bash

sleep 5
err_cnt=0
while [ $err_cnt != 2 ]
do
	if ip netns exec ns_server ping -c 1 192.168.100.99 &> /dev/null
	then
		err_cnt=0
	else
		((err_cnt+=1))
	fi
	sleep 3
done

killall network_stress_test.sh > /dev/null 2>&1
killall iperf3 > /dev/null 2>&1
