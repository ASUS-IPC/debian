#!/bin/bash

version=3.0

COLOR_REST='\e[0m'
COLOR_GREEN='\e[0;32m';
COLOR_RED='\e[0;31m';

log()
{
	logfile=$LOG_PATH/BurnIn.txt
	logfile2="/dev/kmsg"
	echo -e $1 | tee -a $logfile | sudo tee $logfile2
	logger -t BurnIn "$1"
}

declare -A mmc_type_group
for i in `ls /sys/bus/mmc/devices/`
do
	mmc_type_group[$i]=`cat /sys/bus/mmc/devices/$i/type`
done

return_emmc_dev() {
	for i in "${!mmc_type_group[@]}"
	do
		if [[ "${mmc_type_group[$i]}" == "MMC" ]];then
			echo | ls /sys/bus/mmc/devices/$i/block/
		fi
	done
}

return_sd_dev() {
	for i in "${!mmc_type_group[@]}"
	do
		if [[ "${mmc_type_group[$i]}" == "SD" ]];then
			echo | ls /sys/bus/mmc/devices/$i/block/
		fi
	done
}

declare -A disk_type

return_ext_disk_dev() {
	for i in `ls /sys/block/ | grep sd`
	do
		if [ `realpath /sys/block/$i | grep 38100000` ]; then
			disk_type[$i]=USB-C
		elif [ `realpath /sys/block/$i | grep 38200000` ]; then
			disk_type[$i]=USB-A
			if [ `cat /sys/block/$i/removable` == 0 ];then
				disk_type[$i]=MSATA
			fi
		else
			disk_type[$i]=PCIE
		fi
	done
}

emmcdev=`return_emmc_dev`
sddev=`return_sd_dev`
return_ext_disk_dev

select_test_item()
{
	echo "============================================"
	echo
	echo                "PE100A Burn In Test v_$version"
	echo
	echo "============================================"
	echo
	echo "0. (Default) All"
	echo "1. CPU stress test"
	echo "2. GPU stress test"
	echo "3. DDR stress test"
	echo "4. eMMC stress test"
	echo "5. SD card stress test"
	echo "6. External Storage stress test"
	echo "7. Ethernet stress test"
	echo "8. Wi-Fi stress test"
	echo "9. UART loopback stress test"
	echo "10. TPU stres test"
	read -p "Select test case: " test_item
}
info_view()
{
	echo "============================================"
	echo
	echo "          $1 stress test start"
	echo
	echo "============================================"
}

high_performance()
{
	echo
	echo "1. disable thermal policy"
	echo "2. keep thermal policy "
	read -p  "Select thermal policy: " thermal
	echo
	sudo bash $SCRIPTPATH/test/high_performance.sh $thermal > /dev/null 2>&1
}

cpu_freq_stress_test()
{
	logfile=$LOG_PATH/cpu.txt
	time=2592000 # 30 days = 60 * 60 * 24 * 30
	killall stressapptest > /dev/null 2>&1
	sudo bash $SCRIPTPATH/test/cpu_freq_stress_test.sh $SCRIPTPATH $time $logfile > /dev/null 2>&1 &
}

gpu_test()
{
	logfile=$LOG_PATH/gpu.txt
	killall glmark2-es2-wayland > /dev/null 2>&1
    sudo bash $SCRIPTPATH/test/gpu_stress.sh
}

ddr_test()
{
	logfile=$LOG_PATH/ddr.txt
	killall memtester > /dev/null 2>&1
	sudo $SCRIPTPATH/test/memtester $1 > $logfile &
}

emmc_stress_test()
{
	logfile=$LOG_PATH/emmc.txt
	killall emmc_stress_test.sh > /dev/null 2>&1
	$SCRIPTPATH/test/emmc_stress_test.sh $emmcdev $logfile
}

sd_card_stress_test()
{
	logfile=$LOG_PATH/sd.txt
	killall sd_card_stress_test.sh > /dev/null 2>&1
	$SCRIPTPATH/test/sd_card_stress_test.sh $sddev $logfile
}

ext_storage_stress_test()
{
	killall ext_storage_stress_test.sh > /dev/null 2>&1
	if [[ ${#disk_type[@]} -eq 0 ]];then
		ext_disk_exist=0
	else
		ext_disk_exist=1
		for i in "${!disk_type[@]}"
		do
			logfile=$LOG_PATH/${i}.txt
			if [ $1 == "ui" ]; then
				#xterm -fg lightgray -bg black -e "$SCRIPTPATH/test/ext_storage_stress_test.sh $i $logfile" &
				$SCRIPTPATH/test/ext_storage_stress_test.sh $i $logfile
			else
				$SCRIPTPATH/test/ext_storage_stress_test.sh $i $logfile > /dev/null 2>&1 &
			fi
		done
	fi
}

network_stress_test()
{
	logfile=$LOG_PATH/network.txt
	killall network_stress_test.sh > /dev/null 2>&1
	killall iperf3 > /dev/null 2>&1
	$SCRIPTPATH/test/check_network.sh &
	$SCRIPTPATH/test/network_stress_test.sh $SCRIPTPATH $logfile
}

wifi_stress_test()
{
	logfile=$LOG_PATH/wifi.txt
	killall wifi_stress_test.sh > /dev/null 2>&1
	$SCRIPTPATH/test/wifi_stress_test.sh $SCRIPTPATH $logfile
}

uart_stress_test()
{
	logfile1=$LOG_PATH/uart1.txt
	logfile2=$LOG_PATH/uart2.txt
	killall uart1_stress_test.sh > /dev/null 2>&1
	killall uart2_stress_test.sh > /dev/null 2>&1
	killall linux-serial-test > /dev/null 2>&1
	sleep 1
	if [ $1 == "ui" ]; then
		xterm -fg lightgray -bg black -e "$SCRIPTPATH/test/uart2_stress_test.sh $logfile2" &
		sleep 1
		$SCRIPTPATH/test/uart1_stress_test.sh $logfile1
	else
		$SCRIPTPATH/test/uart1_stress_test.sh $logfile1 > /dev/null 2>&1 &
		$SCRIPTPATH/test/uart2_stress_test.sh $logfile2 > /dev/null 2>&1 &
	fi
}

tpu_stress_test()
{
	logfile=$LOG_PATH/tpu.txt
	logfile2=$LOG_PATH/cts.txt
	killall tpu_stress_test.sh > /dev/null 2>&1
	$SCRIPTPATH/test/tpu_stress_test.sh $logfile $logfile2
}

get_device_info()
{
	cpu_usage=$(top -b -n2 -d0.1 | grep "Cpu(s)" | awk '{print $2+$4+$6+$14 "%"}' | tail -n1)

	cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
	cpu_temp=`awk 'BEGIN{printf "%.2f\n",('$cpu_temp'/1000)}'`

	cpu_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`
	cpu_freq=`awk 'BEGIN{printf "%.2f\n",('$cpu_freq'/1000000)}'`

	ddr_freq=`sudo cat /sys/kernel/debug/clk/clk_summary | grep dram_core_clk | awk '{print $4}'`
	ddr_freq=`expr $ddr_freq \* 2 / 1000000`

	gpu_freq=`sudo cat /sys/kernel/debug/gc/clk | grep sh | awk '{print $4}'` #get gpu shader clock
	gpu_freq=`expr $gpu_freq / 1000000`

	gpu_pmstage=`sudo cat /sys/kernel/debug/gc/idle`
	gpu_pmstage_start_time=`echo $gpu_pmstage | awk '{print $2}'`
	gpu_pmstage_end_time=`echo $gpu_pmstage | awk '{print $5}'`
	gpu_pmstage_on_time=`echo $gpu_pmstage | awk '{print $8}'`
	gpu_pmstage_duration=`expr $gpu_pmstage_end_time - $gpu_pmstage_start_time`
	gpu_usage_temp=`awk 'BEGIN{printf "%.2f\n",('$gpu_pmstage_on_time'/'$gpu_pmstage_duration'*100)}'`

	if [ -z $gpu_usage ]
	then
		gpu_usage=$gpu_usage_temp
	else
		gpu_usage=`awk 'BEGIN{printf "%.2f\n",(('$gpu_usage'+'$gpu_usage_temp')/2)}'`
	fi
}

CPU="/test/stressapptest -s 864000 --pause_delay 3600 --pause_duration 1 -W --stop_on_errors"
GPU="glmark2-es2-wayland --benchmark refract --run-forever --off-screen"
DDR="/test/memtester"
EMMC="/test/emmc_stress_test.sh"
SD="/test/sd_card_stress_test.sh"
Ethernet="/test/network_stress_test.sh"
UART1="/test/uart1_stress_test.sh"
UART2="/test/uart2_stress_test.sh"
TPU="tpu_stress_test.sh"

check_status()
{
	Flag=$( ps aux | grep "$2" | grep -v "grep")
	if [ "$Flag" == ""  ]
	then
		log "$1 stress test : ${COLOR_RED}stop${COLOR_REST} "
	else
		log "$1 stress test : ${COLOR_GREEN}running${COLOR_REST} "
	fi
}

check_ext_storage_status()
{
	if [ "$ext_disk_exist" == 0 ];then
		log "Ext Storage stress test: ${COLOR_RED}stop${COLOR_REST} "
	else
		for i in "${!disk_type[@]}"
		do
			if [ -f $LOG_PATH/${i}.txt ]; then
				Flag=`tail -n1 $LOG_PATH/${i}.txt | awk '{print $4}'`
				if [ "$Flag" == "pass"  ]
				then
					log "${disk_type[$i]}-${i} stress test : ${COLOR_GREEN}running${COLOR_REST} "
				else
					log "${disk_type[$i]}-${i} stress test : ${COLOR_RED}stop${COLOR_REST} "
				fi
			else
				log "${disk_type[$i]}-${i} stress test : ${COLOR_RED}stop${COLOR_REST} "
			fi
		done
	fi
}

check_wifi()
{
	if [ -f $LOG_PATH/wifi.txt ]; then
		Flag=`tail -n1 $LOG_PATH/wifi.txt | awk '{print $4}'`
		if [ "$Flag" == "fail"  ]
		then
			log "WiFi stress test : ${COLOR_RED}stop${COLOR_REST} "
		else
			log "WiFi stress test : ${COLOR_GREEN}running${COLOR_REST} "
		fi
	else
		log "WiFi stress test : ${COLOR_RED}stop${COLOR_REST} "
	fi
}

check_all_status()
{
	check_status CPU $CPU
	check_status GPU $GPU
	check_status DDR $DDR
	check_status EMMC $EMMC
	check_status SD $SD
	check_ext_storage_status
	check_status Ethernet $Ethernet
	check_wifi
	check_status UART1 $UART1
	check_status UART2 $UART2
	check_status TPU $TPU
}

check_system_status=false
SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
select_test_item
high_performance
chmod 755 $SCRIPTPATH/test/*.sh

now="$(date +'%Y%m%d_%H%M')"
LOG_PATH=/var/log/burnin_test/$now
mkdir -p $LOG_PATH

case $test_item in
	1)
		check_system_status=true
		info_view CPU
		cpu_freq_stress_test
		;;
	2)
		check_system_status=true
		info_view GPU
		gpu_test
		;;
	3)
		check_system_status=true
		info_view DDR
		ddr_test 512MB
		;;
	4)
		info_view eMMC_RW
		emmc_stress_test
		;;
	5)
		info_view SD_RW
		sd_card_stress_test
		;;
	6)
		info_view Extnal_Storage_RW
		ext_storage_stress_test ui
		;;
	7)
		info_view Ethernet
		network_stress_test
		;;
	8)
		info_view WiFi
		wifi_stress_test
		;;
	9)
		info_view UART loopback
		uart_stress_test ui
		;;
	10)
		info_view TPU
		tpu_stress_test
		;;
	*)
		check_system_status=true
		info_view BurnIn
		cpu_freq_stress_test
		gpu_test
		ddr_test 32MB
		emmc_stress_test > /dev/null 2>&1 &
		sd_card_stress_test > /dev/null 2>&1 &
		ext_storage_stress_test bk
		network_stress_test > /dev/null 2>&1 &
		wifi_stress_test > /dev/null 2>&1 &
		uart_stress_test bk
		tpu_stress_test > /dev/null 2>&1 &
		;;
esac

while true; do
	if [ $check_system_status == false ]; then
		exit
	fi
	get_device_info
	log ""
	log "============================================"
	log "$(date)"
	log "CPU Usage      = $cpu_usage"
	log "GPU Usage      = $gpu_usage"
	log "CPU temp       = $cpu_temp"
	log "CPU freq       = $cpu_freq GHz"
	log "GPU freq       = $gpu_freq MHz"
	log "DDR freq       = $ddr_freq MHz"
	log ""
	log "Test Status"
	check_all_status
	log "============================================"
	log ""
	sleep 9
done
