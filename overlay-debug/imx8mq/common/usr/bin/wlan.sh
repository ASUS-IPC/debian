#!/bin/bash

while true
do
	echo "========================================="
	echo "      WLAN Test Menu                     "
	echo "========================================="
	echo "(1)WLAN Scan"
	echo "(2)WLAN Connect"
	echo "(3)WLAN Disconnect"
	echo -n "Input Selection : "
	read option
	case $option in
		"1")
			echo "WLAN Scan"
			nmcli dev wifi rescan
			sleep 3
			nmcli dev wifi
			;;
		"2")
			echo "Connect with user input..."
			echo -n "AP with hidden SSID (y/n)"
			read hidden
			echo -n "Input SSID: "
			read ssid
			echo -n "Input PASSWORD: "
			read key
			if [ "$hidden" == "y" -o "$hidden" == "Y" ]; then
				nmcli c add type wifi con-name $ssid ifname wlan0 ssid $ssid
				if [ ! -z $key ]; then
					nmcli c modify $ssid wifi-sec.key-mgmt wpa-psk wifi-sec.psk $key
				fi
				nmcli c up $ssid
			else
				nmcli dev wifi connect $ssid password "$key" ifname wlan0
			fi
			;;
		"3")	nmcli dev disconnect iface wlan0
			;;
		*)
			echo "No support opton, exit..."
			;;
	esac
done

