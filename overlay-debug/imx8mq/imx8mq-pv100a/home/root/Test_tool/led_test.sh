#!/bin/bash

func=$1
mode=$2

WIFI_RED="/sys/class/leds/wifi-led-r/brightness"
WIFI_GREEN="/sys/class/leds/wifi-led-g/brightness"
LTE_RED="/sys/class/leds/lte-led-r/brightness"
LTE_GREEN="/sys/class/leds/lte-led-g/brightness"
GPS_RED="/sys/class/leds/gps-led-r/brightness"
GPS_GREEN="/sys/class/leds/gps-led-g/brightness"

if [ "$func" == "0" ]; then
    if [ "$mode" == "0" ]; then
        echo "set wifi led to off"
        echo 0 > "${WIFI_RED}"
        echo 0 > "${WIFI_GREEN}"
    elif [ "$mode" == "1" ]; then
        echo "set wifi led to green"
        echo 0 > "${WIFI_RED}"
        echo 1 > "${WIFI_GREEN}"
    elif [ "$mode" == "2" ]; then
        echo "set wifi led to red"
        echo 1 > "${WIFI_RED}"
        echo 0 > "${WIFI_GREEN}"
    elif [ "$mode" == "3" ]; then
        echo "set wifi led to yellow"
        echo 1 > "${WIFI_RED}"
        echo 1 > "${WIFI_GREEN}"
    else
        echo "invalid mode"
    fi
elif [ "$func" == "1" ]; then
    if [ "$mode" == "0" ]; then
        echo "set lte led to off"
        echo 0 > "${LTE_RED}"
        echo 0 > "${LTE_GREEN}"
    elif [ "$mode" == "1" ]; then
        echo "set lte led to green"
        echo 0 > "${LTE_RED}"
        echo 1 > "${LTE_GREEN}"
    elif [ "$mode" == "2" ]; then
        echo "set lte led to red"
        echo 1 > "${LTE_RED}"
        echo 0 > "${LTE_GREEN}"
    elif [ "$mode" == "3" ]; then
        echo "set lte led to yellow"
        echo 1 > "${LTE_RED}"
        echo 1 > "${LTE_GREEN}"
    else
        echo "invalid mode"
    fi
elif [ "$func" == "2" ]; then
    if [ "$mode" == "0" ]; then
        echo "set gps led to off"
        echo 0 > "${GPS_RED}"
        echo 0 > "${GPS_GREEN}"
    elif [ "$mode" == "1" ]; then
        echo "set gps led to green"
        echo 0 > "${GPS_RED}"
        echo 1 > "${GPS_GREEN}"
    elif [ "$mode" == "2" ]; then
        echo "set gps led to red"
        echo 1 > "${GPS_RED}"
        echo 0 > "${GPS_GREEN}"
    elif [ "$mode" == "3" ]; then
        echo "set gps led to yellow"
        echo 1 > "${GPS_RED}"
        echo 1 > "${GPS_GREEN}"
    else
        echo "invalid mode"
        exit 1
    fi
else
    echo "invalid func"
    exit 1
fi

exit 0


