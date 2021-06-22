#!/bin/bash

version=2.1

select_test_item()
{
	echo "*******************************************"
	echo
	echo                "System Test tool v_$version"
	echo
	echo "*******************************************"
	echo
	echo "1. Start shutdown test (need to manual power on/off)"
	echo "2. Start reboot test"
	echo "3. Start suspend test"
	echo "4. Stop test"
	echo "5. Check test count"
	read -p "Select test case: " test_item
	echo
}

info_view()
{
	echo "*******************************************"
	echo
	echo "          $1 stress test start"
	echo
	echo "*******************************************"
	echo "Reset test counter"
	sudo rm /etc/*_times.txt
}

pause(){
        read -n 1 -p "$*" INP
        if [ $INP != '' ] ; then
                echo -ne '\b \n'
        fi
}

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`/etc
if [ $1 ];then
	test_item=$1
else
	select_test_item
fi

#sudo bash /usr/bin/scan_io.sh

case $test_item in
	1)
		info_view Shutdown
		sudo cp $SCRIPTPATH/shutdown_test.sh /etc/init.d/
		sudo update-rc.d shutdown_test.sh defaults
		sudo update-rc.d shutdown_test.sh enable
		sudo bash -c "echo +20 > /sys/class/rtc/rtc0/wakealarm"
		sleep 5
		sudo systemctl poweroff
		;;
	2)
		info_view Reboot
		sudo cp $SCRIPTPATH/reboot_test.sh /etc/init.d/
		sudo update-rc.d reboot_test.sh defaults
		sudo update-rc.d reboot_test.sh enable
		sleep 5
		sudo systemctl reboot
		;;
	3)
		info_view Suspend
		times=0
		while true; do
			sudo bash $SCRIPTPATH/suspend_test.sh
			echo "suspend_times = "$times | sudo tee /etc/suspend_times.txt
			sleep 20
			((times+=1))
			if [ "$times" = 1 ]; then
				sudo bash /usr/bin/scan_io.sh
			fi
			dmesg > $SCRIPTPATH/dmesg
			result=`/usr/bin/check_io.sh | grep Fail`
			if [ -n "$result" ]; then
				echo $result >> /etc/suspend_times.txt
				exit
			fi
		done
		;;
	4)
		echo "Stop test, device will reboot again after 5 second"
		sudo update-rc.d -f reboot_test.sh remove
		sudo update-rc.d -f shutdown_test.sh remove
		sudo bash -c "$SCRIPT 5"
		sleep 5
		sudo systemctl reboot
		;;
	5)
		if [ -f /etc/shutdown_times.txt ]; then
			cat /etc/shutdown_times.txt
		fi
		if [ -f /etc/reboot_times.txt ]; then
			cat /etc/reboot_times.txt
		fi
		if [ -f /etc/suspend_times.txt ]; then
			cat /etc/suspend_times.txt
		fi
		;;
	*)
		echo "Unknown test case!"
		;;
esac

#pause 'Press any key to exit...'
