#!/bin/bash

#disalbe thermal
echo "Setting CPU / GPU / DDR in highest performance mode"
echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

if [ $1 -a $1 == 2 ]; then
	echo keep thermal
	echo 95000 > /sys/class/thermal/thermal_zone0/trip_point_0_temp
	echo 110000 > /sys/class/thermal/thermal_zone0/trip_point_1_temp
else
	echo disable thermal
	if [ -e /sys/class/thermal/thermal_zone0 ]; then
		echo user_space >/sys/class/thermal/thermal_zone0/policy
		echo disabled > /sys/class/thermal/thermal_zone0/mode
		echo 0 > /sys/class/thermal/thermal_zone0/cdev0/cur_state
		echo 0 > /sys/class/thermal/thermal_zone0/cdev1/cur_state
		echo 0 > /sys/class/thermal/thermal_zone0/cdev2/cur_state
		echo 0 > /sys/class/thermal/thermal_zone0/cdev3/cur_state
	fi
fi
