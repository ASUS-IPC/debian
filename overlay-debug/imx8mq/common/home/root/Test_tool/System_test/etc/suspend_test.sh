#!/bin/bash

echo 0 > /sys/class/rtc/rtc0/wakealarm
echo 0 > /sys/class/rtc/rtc1/wakealarm
echo +20 > /sys/class/rtc/rtc0/wakealarm
echo +20 > /sys/class/rtc/rtc1/wakealarm
#echo -n mem > /sys/power/state
systemctl suspend
