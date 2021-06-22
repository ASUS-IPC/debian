#!/bin/bash

### BEGIN INIT INFO
# Provides:          reboot_test.sh
# Required-Start:    $all
# Required-Stop:     
# Should-Stop:       
# Default-Start:     2 3 4 5
# X-Start-Before:  
# Default-Stop:      
# Short-Description: Reboot auto test tool
### END INIT INFO

times=$(grep -r "reboot_times" /etc/reboot_times.txt | awk '{print $3}')

case "$1" in
	start)
		((times+=1))
		sleep 60
		if [ "$times" = 1 ]; then
			sudo bash /usr/bin/scan_io.sh
		fi
		echo "reboot_times = "$times | sudo tee /etc/reboot_times.txt
		result=`/usr/bin/check_io.sh | grep Fail`
		if [ -n "$result" ]; then
			echo $result >> /etc/reboot_times.txt
			sudo update-rc.d -f reboot_test.sh remove
			exit
		fi
		sync
#		systemctl reboot
		echo 1 | sudo tee /proc/sys/kernel/sysrq
		echo b | sudo tee /proc/sysrq-trigger
		;;
	stop)
		echo "Stopping reboot_test"
		;;
	*)
		echo "Usage: /etc/init.d/reboot_test.sh {start|stop}"
		exit 1
		;;
esac

exit 0
