TOOLPATH=/home/root/Test_tool/GPS_test
GPSPORT=/dev/ttymxc3
ATPORT=/dev/ttyUSB2
ACK=/at_ack
GPSMODULE="ublox"
baudrate=9600
DATE=$(date +%Y%m%d%H%M%S)
mkdir /var/log/gps 2> /dev/null
LogFile=/var/log/gps/$DATE-GPSTest-FW.log
LogFile1=/var/log/gps/$DATE-GPSTest-CN.log
LogFile2=/var/log/gps/$DATE-GPSTest-TTFF.log
LogFile3=/var/log/gps/GPSTest-CheckModule.log
def_debug=false
UBLOX_HW_RESET="\xB5\x62\x06\x04\x04\x00\x00\x00\x00\x00\x0E\x64"
UBLOX_SW_RESET_GNSS="\xB5\x62\x06\x04\x04\x00\x00\x00\x02\x00\x10\x68"
UBLOX_SW_RESET_GNSS_DELETE_ALL="\xB5\x62\x06\x04\x04\x00\xFF\xFF\x02\x00\x0E\x61"
UBLOX_STOP_GPS_DELETE_ALL="\xB5\x62\x06\x04\x04\x00\xFF\xB9\x08\x00\xCE\x9B"
UBLOX_STOP_GPS="\xB5\x62\x06\x04\x04\x00\x00\x00\x08\x00\x16\x74"
UBLOX_FACTORY_RESET="\xB5\x62\x06\x09\x0D\x00\xFF\xFB\x00\x00\x00\x00\x00\x00\xFF\xFF\x00\x00\x17\x2B\x7E"

script_version="3.6.20210609"

if [ -f $LogFile ]; then
  rm $LogFile
fi

if [ "$5" == "1" ]; then
   def_debug=true
fi

function TTFF(){
	spec=$2
	if [ "$1" == 0 ]; then
		GPSMODULE="ublox"
	elif [ "$1" == 1 ]; then
		GPSMODULE="locosys"
	else
		help
		exit
	fi
	if [[ $GPSMODULE == 'ublox' ]]; then
		baudrate=9600
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			echo -ne $UBLOX_SW_RESET_GNSS_DELETE_ALL > $GPSPORT
			sleep 1
		else
			echo "Error: Baud rate is $current_baudrate" >> $LogFile1
		fi
	elif [[ $GPSMODULE == 'locosys' ]]; then
		baudrate=115200
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			# Do locosys full cold start
			echo -ne "\x24\x50\x4D\x54\x4B\x31\x30\x34\x2A\x33\x37\x0D\x0A" > $GPSPORT
			sleep 1
			count=0
		else
			echo "Error: Baud rate is $current_baudrate" >> $LogFile1
		fi
	fi
	
	count=0
	cat $GPSPORT | while read -r line; do
		NMEAHead=`echo $line | awk -F "," '{print $1}'`
		echo "$line" >> $LogFile2
		if [[ $NMEAHead == '$GNGGA' ]]; then
			count=$(($count+1))
			data0=`echo "$line" | cut -d',' -f3`
			data1=`echo "$line" | cut -d',' -f5`

			if [ "$data0" != "" ] && [ "$data1" != "" ]; then
				echo "TTFF:$count"
				echo "pos0=[$data0], pos1=[$data1]"
				# Stop GPS and Delete all
				echo -ne $UBLOX_STOP_GPS_DELETE_ALL >  $GPSPORT
				break
			fi
		fi
	done
	
}

function getSVfromGPSD(){
    echo -ne $UBLOX_SW_RESET_GNSS_DELETE_ALL > $GPSPORT
    /home/root/Test_tool/GPS_test/gpsd/gpspipe -R -n600 | grep GPGSV > $LogFile
    input=$LogFile1
    i=0

    while IFS= read -r line
    do
    	i=$(($i+1))
		echo $line
    	totalSV=`echo "$line" | cut -d',' -f4`
    	SVid1=`echo "$line" | cut -d',' -f5`
		SVcn1=`echo "$line" | cut -d',' -f8`
		SVid2=`echo "$line" | cut -d',' -f9`
		SVcn2=`echo "$line" | cut -d',' -f12`
		SVid3=`echo "$line" | cut -d',' -f13`
		SVcn3=`echo "$line" | cut -d',' -f16`
    	if [ "$SVid1" != "" ] && [ "$SVcn1" != "" ]; then
			echo "SVid=$SVid1,$SVcn1,$SVid2,$SVcn2,$SVid3,$SVcn3" 
    	fi
    done < "$input"
}

function getSV(){
	spec_count=$2
	if [ "$1" == 0 ]; then
		GPSMODULE="ublox"
	elif [ "$1" == 1 ]; then
		GPSMODULE="locosys"
	else
		help
		exit
	fi
	if [[ $GPSMODULE == 'ublox' ]]; then
		baudrate=9600
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			echo "Reset GPS" >> $LogFile1
			echo -ne $UBLOX_SW_RESET_GNSS_DELETE_ALL >  $GPSPORT
			sleep 1
			count=0
			cat $GPSPORT | while read -r line; do
				#set -x
				NMEAHead=`echo $line | awk -F "," '{print $1}'`
				#set +x 
				echo "$line" >> $LogFile1
				if [[ $NMEAHead == '$GPGSV' ]]; then
					if $def_debug ; then
						echo "Processing $line"
					fi
					totalSV=`echo "$line" | cut -d',' -f4`
					SVid1=`echo "$line" | awk -F "," '{print $5}'`
					SVcn1=`echo "$line" | awk -F "," '{print $8}'`
					SVcn1=`echo "$SVcn1"  | awk -F "*" '{print $1}'`
					SVid2=`echo "$line" | awk -F "," '{print $9}'`
					SVcn2=`echo "$line" | awk -F "," '{print $12}'`
					SVcn2=`echo "$SVcn2"  | awk -F "*" '{print $1}'`
					SVid3=`echo "$line" | awk -F "," '{print $13}'`
					SVcn3=`echo "$line" | awk -F "," '{print $16}'`
					SVcn3=`echo "$SVcn3"  | awk -F "*" '{print $1}'`
					SVid4=`echo "$line" | awk -F "," '{print $17}'`
					SVcn4=`echo "$line" | awk -F "," '{print $20}'`
					SVcn4=`echo "$SVcn4"  | awk -F "*" '{print $1}'`
					if [ "$SVid1" != "" ] && [ "$SVcn1" != "" ]; then
						printf "SVid=$SVid1,CN0=$SVcn1\n"
					elif [ "$SVid2" != "" ] && [ "$SVid2" != "" ]; then
						printf "SVid=$SVid2,CN0=$SVid2\n"
					elif [ "$SVid3" != "" ] && [ "$SVid3" != "" ]; then
						printf "SVid=$SVid3,CN0=$SVid3\n"
					elif [ "$SVid4" != "" ] && [ "$SVid4" != "" ]; then
						printf "SVid=$SVid4,CN0=$SVid4\n"
					fi
				fi
				if [[ $NMEAHead == '$GNGGA' ]]; then
					((++count))
					if $def_debug ; then
						echo "count: $count Processing $line"
					else
						echo "count: $count" >> $LogFile1
					fi
					
					if [ $count == $spec_count ]; then
						# Stop GPS and Delete all
						echo -ne $UBLOX_STOP_GPS_DELETE_ALL >  $GPSPORT
						break
					fi
				fi
			done
		else
			echo "Error: Baud rate is $current_baudrate" >> $LogFile1
		fi
	elif [[ $GPSMODULE == 'locosys' ]]; then
		baudrate=115200
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			# Do locosys full cold start
			echo -ne "\x24\x50\x4D\x54\x4B\x31\x30\x34\x2A\x33\x37\x0D\x0A" > $GPSPORT
			sleep 1
			count=0
			cat $GPSPORT | while read -r line; do
				NMEAHead=`echo $line | awk -F "," '{print $1}'`
				echo "$line" >> $LogFile1
				if [[ $NMEAHead == '$GPGSV' ]]; then
					if $def_debug ; then
						echo "Processing $line"
					fi
					totalSV=`echo "$line" | cut -d',' -f4`
					SVid1=`echo "$line" | awk -F "," '{print $5}'`
					SVcn1=`echo "$line" | awk -F "," '{print $8}'`
					SVcn1=`echo "$SVcn1"  | awk -F "*" '{print $1}'`
					SVid2=`echo "$line" | awk -F "," '{print $9}'`
					SVcn2=`echo "$line" | awk -F "," '{print $12}'`
					SVcn2=`echo "$SVcn2"  | awk -F "*" '{print $1}'`
					SVid3=`echo "$line" | awk -F "," '{print $13}'`
					SVcn3=`echo "$line" | awk -F "," '{print $16}'`
					SVcn3=`echo "$SVcn3"  | awk -F "*" '{print $1}'`
					SVid4=`echo "$line" | awk -F "," '{print $17}'`
					SVcn4=`echo "$line" | awk -F "," '{print $20}'`
					SVcn4=`echo "$SVcn4"  | awk -F "*" '{print $1}'`
					if [ "$SVid1" != "" ] && [ "$SVcn1" != "" ]; then
						printf "SVid=$SVid1,CN0=$SVcn1\n"
					elif [ "$SVid2" != "" ] && [ "$SVid2" != "" ]; then
						printf "SVid=$SVid2,CN0=$SVid2\n"
					elif [ "$SVid3" != "" ] && [ "$SVid3" != "" ]; then
						printf "SVid=$SVid3,CN0=$SVid3\n"
					elif [ "$SVid4" != "" ] && [ "$SVid4" != "" ]; then
						printf "SVid=$SVid4,CN0=$SVid4\n"
					fi
				fi
				if [[ $NMEAHead == '$GNGGA' ]]; then
					((++count))
					if $def_debug ; then
						echo "count: $count Processing $line"
					else
						echo "count: $count" >> $LogFile1
					fi
					
					if [ $count == $spec_count ]; then
						break
					fi
				fi
			done
		else
			echo "Error: Baud rate is $current_baudrate" >> $LogFile1
		fi
	fi
}

function getSVwithIQXtream(){
	spec_count=$2
	spec=$3
	value=0
	count=0
	value_count=0
	time_out=30
	#detectModule $LogFile1 $1
	#retval=$?
	#if [ "$retval" == 0 ]; then
	#	echo "FAILValue=-999"
	#	return
	#fi
	if [ "$1" == 0 ]; then
		GPSMODULE="ublox"
	elif [ "$1" == 1 ]; then
		GPSMODULE="locosys"
	else
		help
		exit
	fi
	echo "getSVwithIQXtream: $GPSMODULE" >> $LogFile1
	if [[ $GPSMODULE == 'ublox' ]]; then
		baudrate=9600
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			# SW Reset and Delete all
			echo "SW Reset GNSS task and Delete all, spec: $spec , timeout=$time_out" >> $LogFile1
			echo -ne $UBLOX_SW_RESET_GNSS_DELETE_ALL >  $GPSPORT
			cat $GPSPORT | while read -r line; do
				#set -x
				NMEAHead=`echo $line | awk -F "," '{print $1}'`
				#set +x 
				echo "$line" >> $LogFile1

				if [[ $NMEAHead == '$GPGSV' ]]; then
					if $def_debug ; then
						echo "Processing $line" 
					fi
					totalSV=`echo "$line" | cut -d',' -f4`
					SVid1=`echo "$line" | awk -F "," '{print $5}'`
					SVcn1=`echo "$line" | awk -F "," '{print $8}'`
					SVcn1=`echo "$SVcn1"  | awk -F "*" '{print $1}'`
					if [ "$SVid1" == "01" ] && [ "$SVcn1" != "" ]; then
						value=$((value+SVcn1))
						((++value_count))
						if $def_debug ; then
							echo "SVid=$SVid1,CN0=$SVcn1, value=$value, value_count=$value_count"
						else
							echo "SVid=$SVid1,CN0=$SVcn1, value=$value, value_count=$value_count" >> $LogFile1
						fi
					fi
				elif [[ $NMEAHead == '$GNGGA' ]]; then
					((++count))
					if [ $value_count == $spec_count ]; then
						value=$((value/value_count))
						if $def_debug ; then
							echo "value=$value, value_count=$value_count, count=$count" 
						else
							echo "value=$value, value_count=$value_count" >> $LogFile1
						fi
			
						if [ $value -ge $spec ]; then
							printf "PASSValue=$value\n"
						else
							printf "FAILValue=$value\n"
						fi
						# Stop GPS and Delete all
						# echo -ne $UBLOX_STOP_GPS_DELETE_ALL >  $GPSPORT
						break
					elif [ $count -ge $time_out ]; then
						printf "FAILValue=0\n"
						# Stop GPS and Delete all
						# echo -ne $UBLOX_STOP_GPS_DELETE_ALL >  $GPSPORT
						break
					fi
				#$GNTXT,01,01,02,Stopping GNSS*52
				#$GNTXT,01,01,02,Resetting GNSS*3B
				fi
			done
		else
			echo "Error: Baud rate is $current_baudrate" >> $LogFile1
			echo "FAILValue=-998"
		fi
	elif [[ $GPSMODULE == 'locosys' ]]; then
		echo "Do full cold start for locosys , spec: $spec , timeout=$time_out" >> $LogFile1
		baudrate=115200
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			# Do locosys full cold start
			echo -ne "\x24\x50\x4D\x54\x4B\x31\x30\x34\x2A\x33\x37\x0D\x0A" > $GPSPORT
			cat $GPSPORT | while read -r line; do
				NMEAHead=`echo $line | awk -F "," '{print $1}'`
				echo "$line" >> $LogFile1

				if [[ $NMEAHead == '$GPGSV' ]]; then
					if $def_debug ; then
						echo "Processing $line" 
					fi
					totalSV=`echo "$line" | cut -d',' -f4`
					SVid1=`echo "$line" | awk -F "," '{print $5}'`
					SVcn1=`echo "$line" | awk -F "," '{print $8}'`
					SVcn1=`echo "$SVcn1"  | awk -F "*" '{print $1}'`
					if [ "$SVid1" == "01" ] && [ "$SVcn1" != "" ]; then
						value=$((value+SVcn1))
						((++value_count))
						if $def_debug ; then
							echo "SVid=$SVid1,CN0=$SVcn1, value=$value, value_count=$value_count"
						else
							echo "SVid=$SVid1,CN0=$SVcn1, value=$value, value_count=$value_count" >> $LogFile1
						fi
					fi
				elif [[ $NMEAHead == '$GNGGA' ]]; then
					((++count))
					if [ $value_count == $spec_count ]; then
						value=$((value/value_count))
						if $def_debug ; then
							echo "value=$value, value_count=$value_count, count=$count" 
						else
							echo "value=$value, value_count=$value_count" >> $LogFile1
						fi
			
						if [ $value -ge $spec ]; then
							printf "PASSValue=$value\n"
						else
							printf "FAILValue=$value\n"
						fi
						break
					elif [ $count -ge $time_out ]; then
						printf "FAILValue=0\n"
						# Stop GPS and Delete all
						break
					fi
				fi
			done
		else
			echo "Error: Baud rate is $current_baudrate" >> $LogFile1
			echo "FAILValue=-998"
		fi
	fi 
}

function CheckInfo(){
	#detectModule $LogFile $1
	#retval=$?
	#if [ "$retval" == 0 ]; then
	#	echo "FAIL"
	#	return
	#fi
	if [ "$1" == 0 ]; then
		GPSMODULE="ublox"
	elif [ "$1" == 1 ]; then
		GPSMODULE="locosys"
	fi
	echo "CheckInfo: $GPSMODULE" >> $LogFile
	if [[ $GPSMODULE == 'ublox' ]]; then
		baudrate=9600
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			echo "send Hot SW Reset GPS" >> $LogFile
			#echo -ne "\xB5\x62\x06\x04\x04\x00\x00\x00\x01\x00\x0F\x66" >  $GPSPORT
			echo -ne $UBLOX_HW_RESET >  $GPSPORT
			
			cat $GPSPORT | while read -r line; do
				#set -x
				NMEAHead=`echo $line | awk -F "," '{print $1}'`
				#set +x 
				if $def_debug ; then
					echo "Processing $line"
				else
					echo "$line"  >> $LogFile
				fi
				if [[ $NMEAHead == '$GNTXT' ]]; then
					if $def_debug ; then
						echo "Processing $line"
					fi
					result=`echo "$line" | awk -F "," '{print $5}'`
					result=`echo "$result" | awk -F "*" '{print $1}'`
					printf "$result\n"
					if [ "$result" == 'ANTSTATUS=OK' ]; then
						break
					fi
				fi
			done
		else
			echo "Error: Baud rate is $current_baudrate"
			return 0
		fi
	elif [[ $GPSMODULE == 'locosys' ]]; then
		baudrate=115200
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			cat $GPSPORT | while read -r line; do
				NMEAHead=`echo $line | awk -F "," '{print $1}'`
				echo "$line"  >> $LogFile
				if $def_debug ; then
					echo "Processing $line"
				else
					echo "$line"  >> $LogFile
				fi
				if [[ $NMEAHead == '$PINVMVER' ]]; then
					if $def_debug ; then
						echo "Processing $line"
					fi
					result1=`echo "$line" | awk -F "," '{print $2}'`
					result2=`echo "$line" | awk -F "," '{print $3}'`
					printf "$result1 $result2\n"
					if [ ! -z $result1 ]; then
						break
					fi
				else
					echo "Send PLSC,VER*61 to $GPSPORT"  >> $LogFile
					echo -ne "\x24\x50\x4C\x53\x43\x2C\x56\x45\x52\x2A\x36\x31\x0D\x0A" > $GPSPORT
				fi
			done
		else
			echo "Error: Baud rate is $current_baudrate"
			return 0
		fi
	fi
}

function CheckModule(){
	# Reset GPS
	detectModule $LogFile3 $1
	retval=$?
	if [ "$retval" == 1 ]; then
		echo "PASS"
	else
		echo "FAIL"
	fi
}

function detectModule(){
	if [ "$2" == 0 ]; then
		GPSMODULE="ublox"
	elif [ "$2" == 1 ]; then
		GPSMODULE="locosys"
	fi
	echo "$DATE detectModule: $GPSMODULE" >> $1
	# HW Reset GPS
	if [[ $GPSMODULE == 'ublox' ]]; then
		baudrate=9600
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			echo "send HW Reset GPS" >> $1
			echo -ne $UBLOX_HW_RESET >  $GPSPORT
			
			sleep 1
			busybox microcom -t 2000 -s $baudrate $GPSPORT | while read -r line; do
				NMEAHead=`echo $line | awk -F "," '{print $1}'`
				echo "$line"  >>  $1
				if $def_debug ; then
					echo "Processing $line"
				fi
				if [[ $NMEAHead == '$GNTXT' ]]; then
					# Stop GPS
					#echo "send stop GPS" >> $1
					#echo -ne $UBLOX_STOP_GPS >  $GPSPORT
					break
				fi
			done
			if  ! OUTPUT=$(cat $1 | grep GNTXT > /dev/null); then
				# GPS module no response, may be module not insert
				return 0
			else 
				return 1
			fi
		else
			echo "Error: Baud rate is $current_baudrate"
			return 0
		fi
	elif [[ $GPSMODULE == 'locosys' ]]; then
		#GPSPORT=/dev/ttyUSB0
		baudrate=115200
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			# Do locosys full cold start
			echo -ne "\x24\x50\x4D\x54\x4B\x31\x30\x34\x2A\x33\x37\x0D\x0A" > $GPSPORT
			busybox microcom -t 2000 -s $baudrate $GPSPORT | while read -r line; do
				NMEAHead=`echo $line | awk -F "," '{print $1}'`
				echo "$line"  >>  $1
				if $def_debug ; then
					echo "Processing $line"
				fi
				if [[ $NMEAHead == '$GNRMC' ]]; then
					break
				fi
			done
			if  ! OUTPUT=$(cat $1 | grep GNRMC > /dev/null); then
				# GPS module no response, may be module not insert
				return 0
			else 
				return 1
			fi
		else
			echo "Error: Baud rate is $current_baudrate"
			return 0
		fi
	fi
	
}

function enableUBX(){
	if [ "$1" == 1 ]; then
		echo "enable UBX"
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x30\x01\x46\xC1" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x50\x01\x66\x01" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x32\x01\x48\xC5" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x33\x01\x49\xC7" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x31\x01\x47\xC3" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x02\x01\x18\x65" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x01\x01\x17\x63" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x00\x01\x16\x61" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x14\x01\x2F\x98" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x15\x01\x30\x9A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x02\x01\x1D\x74" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x02\x01\x1D\x74" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x02\x01\x1D\x74" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x03\x01\x1E\x76" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x10\x01\x2B\x90" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x28\x01\x01\x34\xBA" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x28\x02\x01\x35\xBC" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x28\x00\x01\x33\xB8" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x0E\x01\x3A\xBF" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x08\x01\x34\xB3" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x0B\x01\x37\xB9" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x0F\x01\x3B\xC1" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x0D\x01\x39\xBD" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x60\x01\x7E\x39" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x01\x9E\x79" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x01\x9E\x79" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x01\x9E\x79" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x01\x9E\x79" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x01\x9E\x79" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x01\x9E\x79" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x21\x01\x3F\xBB" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x36\x01\x4B\xCA" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x05\x01\x1A\x68" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x09\x01\x1E\x70" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x0B\x01\x20\x74" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x37\x01\x4C\xCC" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x02\x01\x17\x62" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x0D\x01\x22\x78" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x06\x01\x1B\x6A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x35\x01\x4A\xC8" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x20\x01\x35\x9E" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x2B\x01\x40\xB4" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x38\x01\x4D\xCE" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x07\x01\x1C\x6C" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x21\x01\x36\xA0" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x2E\x01\x43\xBA" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x31\x01\x46\xC0" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x0E\x01\x23\x7A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x08\x01\x1D\x6E" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x60\x01\x6C\x03" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x05\x01\x11\x4D" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x22\x01\x2E\x87" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x36\x01\x42\xAF" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x31\x01\x3D\xA5" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x04\x01\x10\x4B" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x3D\x01\x49\xBD" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x40\x01\x4C\xC3" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x61\x01\x6D\x05" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x39\x01\x45\xB5" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x37\x01\x43\xB1" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x13\x01\x1F\x69" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x14\x01\x20\x6B" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x28\x01\x34\x93" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x09\x01\x15\x55" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x34\x01\x40\xAB" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x01\x01\x0D\x45" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x02\x01\x0E\x47" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x07\x01\x13\x51" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x3C\x01\x48\xBB" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x35\x01\x41\xAD" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x32\x01\x3E\xA7" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x43\x01\x4F\xC9" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x42\x01\x4E\xC7" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x06\x01\x12\x4F" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x03\x01\x0F\x49" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x3B\x01\x47\xB9" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x30\x01\x3C\xA3" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x24\x01\x30\x8B" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x25\x01\x31\x8D" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x23\x01\x2F\x89" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x20\x01\x2C\x83" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x26\x01\x32\x8F" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x27\x01\x33\x91" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x21\x01\x2D\x85" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x11\x01\x1D\x65" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x12\x01\x1E\x67" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x30\x01\x3D\xA6" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x31\x01\x3E\xA8" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x61\x01\x6E\x08" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x12\x01\x1F\x6A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x14\x01\x21\x6E" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x72\x01\x7F\x2A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x10\x01\x1D\x66" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x15\x01\x22\x70" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x59\x01\x66\xF8" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x23\x01\x30\x8C" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x32\x01\x3F\xAA" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x11\x01\x1E\x68" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x13\x01\x20\x6C" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x20\x01\x2D\x86" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x27\x04\x01\x36\xBD" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x27\x03\x01\x35\xBB" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x80\x10\x01\x9B\xE0" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x80\x11\x01\x9C\xE2" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x80\x12\x01\x9D\xE4" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x80\x02\x01\x8D\xC4" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x11\x01\x29\x89" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x16\x01\x2E\x93" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x13\x01\x2B\x8D" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x04\x01\x1C\x6F" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x03\x01\x1B\x6D" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x12\x01\x2A\x8B" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x01\x01\x19\x69" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x15\x01\x2D\x91" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x06\x01\x1E\x73" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x09\x01\x01\x15\x5D" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x09\x14\x01\x28\x83" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x09\x02\x01\x16\x5F" >  $GPSPORT
	else
		echo "disable UBX"
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x30\x00\x45\xC0" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x50\x00\x65\x00" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x32\x00\x47\xC4" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x33\x00\x48\xC6" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x31\x00\x46\xC2" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x02\x00\x17\x64" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x01\x00\x16\x62" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0B\x00\x00\x15\x60" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x14\x00\x2E\x97" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x15\x00\x2F\x99" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x02\x00\x1C\x73" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x02\x00\x1C\x73" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x02\x00\x1C\x73" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x03\x00\x1D\x75" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x10\x10\x00\x2A\x8F" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x28\x01\x00\x33\xB9" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x28\x02\x00\x34\xBB" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x28\x00\x00\x32\xB7" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x0E\x00\x39\xBE" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x08\x00\x33\xB2" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x0B\x00\x36\xB8" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x0F\x00\x3A\xC0" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x21\x0D\x00\x38\xBC" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x60\x00\x7D\x38" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x00\x9D\x78" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x00\x9D\x78" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x00\x9D\x78" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x00\x9D\x78" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x00\x9D\x78" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x80\x00\x9D\x78" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x13\x21\x00\x3E\xBA" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x36\x00\x4A\xC9" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x05\x00\x19\x67" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x09\x00\x1D\x6F" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x0B\x00\x1F\x73" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x37\x00\x4B\xCB" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x02\x00\x16\x61" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x0D\x00\x21\x77" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x06\x00\x1A\x69" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x35\x00\x49\xC7" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x20\x00\x34\x9D" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x2B\x00\x3F\xB3" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x38\x00\x4C\xCD" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x07\x00\x1B\x6B" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x21\x00\x35\x9F" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x2E\x00\x42\xB9" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x31\x00\x45\xBF" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x0E\x00\x22\x79" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0A\x08\x00\x1C\x6D" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x60\x00\x6B\x02" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x05\x00\x10\x4C" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x22\x00\x2D\x86" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x36\x00\x41\xAE" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x31\x00\x3C\xA4" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x04\x00\x0F\x4A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x3D\x00\x48\xBC" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x40\x00\x4B\xC2" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x61\x00\x6C\x04" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x39\x00\x44\xB4" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x37\x00\x42\xB0" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x13\x00\x1E\x68" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x14\x00\x1F\x6A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x28\x00\x33\x92" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x09\x00\x14\x54" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x34\x00\x3F\xAA" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x01\x00\x0C\x44" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x02\x00\x0D\x46" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x07\x00\x12\x50" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x3C\x00\x47\xBA" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x35\x00\x40\xAC" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x32\x00\x3D\xA6" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x43\x00\x4E\xC8" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x42\x00\x4D\xC6" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x06\x00\x11\x4E" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x03\x00\x0E\x48" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x3B\x00\x46\xB8" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x30\x00\x3B\xA2" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x24\x00\x2F\x8A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x25\x00\x30\x8C" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x23\x00\x2E\x88" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x20\x00\x2B\x82" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x26\x00\x31\x8E" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x27\x00\x32\x90" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x21\x00\x2C\x84" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x11\x00\x1C\x64" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x01\x12\x00\x1D\x66" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x30\x00\x3C\xA5" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x31\x00\x3D\xA7" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x61\x00\x6D\x07" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x12\x00\x1E\x69" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x14\x00\x20\x6D" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x72\x00\x7E\x29" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x10\x00\x1C\x65" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x15\x00\x21\x6F" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x59\x00\x65\xF7" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x23\x00\x2F\x8B" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x32\x00\x3E\xA9" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x11\x00\x1D\x67" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x13\x00\x1F\x6B" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x02\x20\x00\x2C\x85" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x27\x04\x00\x35\xBC" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x27\x03\x00\x34\xBA" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x80\x10\x00\x9A\xDF" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x80\x11\x00\x9B\xE1" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x80\x12\x00\x9C\xE3" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x80\x02\x00\x8C\xC3" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x11\x00\x28\x88" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x16\x00\x2D\x92" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x13\x00\x2A\x8C" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x04\x00\x1B\x6E" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x03\x00\x1A\x6C" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x12\x00\x29\x8A" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x01\x00\x18\x68" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x15\x00\x2C\x90" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x0D\x06\x00\x1D\x72" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x09\x01\x00\x14\x5C" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x09\x14\x00\x27\x82" >  $GPSPORT
		echo -ne "\xB5\x62\x06\x01\x03\x00\x09\x02\x00\x15\x5E" >  $GPSPORT

	fi 
}

function send_at_command() {
    if [ -e ${ATPORT} ]; then
        echo -ne "${1}\r" | busybox microcom -t 3000 ${ATPORT} > ${ACK}
    else
        echo "ERROR device not found" > ${ACK}
    fi
}
function read_at_result() {
    at_result=`cat ${ACK} | tr -d '\r'`
    if [[ $at_result == *"ERROR"* ]]; then
		echo ${at_result##*${1}}
        at_result="FAIL"
    else
        at_result=`echo ${at_result##*${1}}`
        #at_result=`echo ${at_result%OK*}`
    fi
}
function startGPS(){
	echo "start $GPSMODULE GPS"
	if [[ $GPSMODULE == 'ublox' ]]; then
		echo -ne "\xB5\x62\x06\x04\x04\x00\x00\x00\x09\x00\x17\x76" >  $GPSPORT
	elif [[ $GPSMODULE == 'quectel' ]]; then
		send_at_command "at+qgps=1"
		read_at_result "at+qgps=1"
		if [[ $at_result == *"OK"* ]]; then
			echo "start quectel GPS success"
			break;
	else
			stopGPS
			sleep 1
			startGPS
		fi	
	fi
}
function stopGPS(){
	echo "stop $GPSMODULE GPS"
	if [[ $GPSMODULE == 'ublox' ]]; then
		echo -ne $UBLOX_STOP_GPS >  $GPSPORT
	elif [[ $GPSMODULE == 'quectel' ]]; then
		send_at_command "at+qgpsend"
		read_at_result "at+qgpsend"
		if [[ $at_result == *"OK"* ]]; then
			echo "stop quectel GPS success"
			break;
		fi
	fi
}

function help(){
	tool_version=`$TOOLPATH/gpstest help | grep version`
	echo "---------------------------------------------------------"
	echo "script version : $script_version, tool $tool_version"
	echo "---------------------------------------------------------"
	echo "Factory Test:"
	echo "	0 0(1): check ublox(locosys) module"
	echo "	1 0(1) 10: Get GPS signal for 10 times"
	echo "	2 0(1) 60: Test TTFF 60 sec"
	echo "	3 0(1) 10 40: Get GPS signal 10 times and spec is :40  (For IQXtreams)"
	echo "	4 0(1): Get ublox(locosys) FW version"
	echo "---------------------------------------------------------"
	echo "Fucntion Test:"
	echo "	calibration /dev/ttymxc3 locosys (ublox)"
	echo "	info        /dev/ttymxc3 locosys (ublox , quectel)"
	echo "	coldstart   /dev/ttymxc3 locosys (ublox , quectel)"
	echo "	saveUBX     /dev/ttymxc3 (only ublox)"
	echo "	sw_reset    /dev/ttymxc3 (only ublox)"
	echo "	hw_reset    /dev/ttymxc3 (only ublox)"
	echo "---------------------------------------------------------"
}

case "$1" in
    0)
	    echo "Log:$LogFile3"
        CheckModule $2
    ;;
    1)
	    echo "Log:$LogFile1"
        getSV $2 $3
    ;;
	2)
	    echo "Log:$LogFile2"
        TTFF $2 $3
	;;
    3)
	    echo "Log:$LogFile1"
	    getSVwithIQXtream $2 $3 $4
	;;
	4)
	    echo "Log:$LogFile"
		CheckInfo $2
	;;
	'help')
		help
	;;
	
	'module')
		if [ ! -z "$2" ]; then
			GPSPORT=$2
		fi
		$TOOLPATH/gpstest $GPSPORT module
	;;
	
	'sw_reset')
		if [ ! -z "$2" ]; then
			GPSPORT=$2
			echo "GPSPORT is $GPSPORT"
		fi
		echo "SW RESET-GNSS Task only"
		echo -ne $UBLOX_SW_RESET_GNSS >  $GPSPORT
	;;
	'hw_reset')
		if [ ! -z "$2" ]; then
			GPSPORT=$2
			echo "GPSPORT is $GPSPORT"
		fi
		echo "HW RESET"
		echo -ne $UBLOX_HW_RESET >  $GPSPORT
	;;
	'enableUBX')
		#echo "1: Enable, 0:Disable UBX"
		if [ ! -z "$2" ]; then
			GPSPORT=$2
			echo "GPSPORT is $GPSPORT"
		fi
		stty -F $GPSPORT 9600
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == '9600' ]]; then
			enableUBX $2
		else
			echo "Error: Baud rate is $current_baudrate"
		fi
	;;
	'saveUBX')
		if [ ! -z "$2" ]; then
			GPSPORT=$2
			echo "GPSPORT is $GPSPORT"
		fi
		stty -F $GPSPORT 9600
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == '9600' ]]; then
			enableUBX 1
			sleep 1
			#echo "Logging now"
			$TOOLPATH/gpstest $GPSPORT saveUBX
			#echo "Logging finish"
			stty -F $GPSPORT 9600
			current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
			if [[ $current_baudrate == '9600' ]]; then
				echo "disable UBX"
			enableUBX 0
				echo "dsible UBX done"
			fi	
		else
			echo "Error: Baud rate is $current_baudrate"
		fi
	;;
	'calibration')
		if [ ! -z "$2" ] && [ ! -z "$3" ]
		then
			GPSPORT=$2
			GPSMODULE=$3
			echo "GPSPORT is $GPSPORT, Module is $GPSMODULE"
		else
			help
			exit
		fi
		if [[ $GPSMODULE == 'ublox' ]]; then
			baudrate=9600
		elif [[ $GPSMODULE == 'locosys' ]]; then
			baudrate=115200
		fi
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			if [[ $GPSMODULE == 'ublox' ]]; then
				#echo "Ublox Calibration start"
				#echo "Send SW RESET-GNSS Task and Delete all data"
				echo -ne $UBLOX_SW_RESET_GNSS_DELETE_ALL >  $GPSPORT
			elif [[ $GPSMODULE == 'locosys' ]]; then
				echo "LOCOSYS DR recalibration start"
				#echo "$PINVCRES,0*1A" then delay 500ms and send $PINVCSTR,14*3E
				#echo -ne "\x24\x50\x49\x4E\x56\x43\x52\x45\x53\x2C\x30\x2A\x31\x41\x0D\x0A" > $GPSPORT
				#sleep 0.5
				#echo -ne "\x24\x50\x49\x4E\x56\x43\x53\x54\x52\x2C\x31\x34\x2A\x33\x45\x0D\x0A" > $GPSPORT
				# need check $PINVMSTR,0*05 and $PINVMSTR,2*07
				bSend=0
				busybox microcom -t 2000 -s $baudrate $GPSPORT | while read -r line; do
					NMEAHead=`echo $line | awk -F "," '{print $1}'`
					if [[ $NMEAHead != '$PINVMSTR' ]]; then
						if [ "$bSend" == 0 ]; then
							echo -e "\033[40;33m Send PINVCRES,0*1A\r\033[0m"
							echo -ne "\x24\x50\x49\x4E\x56\x43\x52\x45\x53\x2C\x30\x2A\x31\x41\x0D\x0A" > $GPSPORT
							bSend=1
						fi
					elif [[ $NMEAHead == '$PINVMSTR' ]] && [ "$bSend" == 1 ]; then
						echo -e "\033[40;33m Send PINVCSTR,14*3E\r\033[0m"
						sleep 0.5
						echo -ne "\x24\x50\x49\x4E\x56\x43\x53\x54\x52\x2C\x31\x34\x2A\x33\x45\x0D\x0A" > $GPSPORT
						bSend=2
					elif [[ $NMEAHead == '$PINVMSTR' ]] && [ "$bSend" == 2 ]; then
						echo -e "\033[40;33m $line\033[0m"
						break
					else
						echo "Processing $line"
					fi
				done
			fi
			echo -e "\033[40;31m Run UI \033[0m"
			sleep 2
			$TOOLPATH/gpstest $GPSPORT $GPSMODULE info
		else
			echo "Error: Baud rate is $current_baudrate"
		fi
	;;
	'monitor')
		if [ ! -z "$2" ] && [ ! -z "$3" ]
		then
			GPSPORT=$2
			GPSMODULE=$3
			echo "GPSPORT is $GPSPORT, Module is $GPSMODULE"
		else
			help
			exit
		fi
		if [[ $GPSMODULE == 'ublox' ]] || [[ $GPSMODULE == 'quectel' ]]; then
			baudrate=9600
		elif [[ $GPSMODULE == 'locosys' ]]; then
			baudrate=115200
		fi
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			if [[ $GPSMODULE == 'quectel' ]]; then
				startGPS
			fi
			$TOOLPATH/gpstest $GPSPORT $GPSMODULE monitor
		else
			echo "Error: Baud rate is $current_baudrate"
		fi
	;;
	'info')
		if [ ! -z "$2" ] && [ ! -z "$3" ]
		then
			GPSPORT=$2
			GPSMODULE=$3
			echo "GPSPORT is $GPSPORT, Module is $GPSMODULE"
		else
			help
			exit
		fi
		if [[ $GPSMODULE == 'ublox' ]] || [[ $GPSMODULE == 'quectel' ]]; then
			baudrate=9600
		elif [[ $GPSMODULE == 'locosys' ]]; then
			baudrate=115200
		fi
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			if [[ $GPSMODULE == 'quectel' ]]; then
				startGPS
			fi
			$TOOLPATH/gpstest $GPSPORT $GPSMODULE info
		else
			echo "Error: Baud rate is $current_baudrate"
		fi
	;;
	'coldstart')
		if [ ! -z "$2" ] && [ ! -z "$3" ]
		then
			GPSPORT=$2
			GPSMODULE=$3
			echo "GPSPORT is $GPSPORT, Module is $GPSMODULE"
		else
			help
			exit
		fi
		if [[ $GPSMODULE == 'ublox' ]] || [[ $GPSMODULE == 'quectel' ]]; then
			baudrate=9600
		elif [[ $GPSMODULE == 'locosys' ]]; then
			baudrate=115200
		fi
		stty -F $GPSPORT $baudrate
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == $baudrate ]]; then
			if [[ $GPSMODULE == 'ublox' ]]; then
				# Do ublox SW Reset and Delete all
				echo -ne $UBLOX_SW_RESET_GNSS_DELETE_ALL >  $GPSPORT
			elif [[ $GPSMODULE == 'locosys' ]]; then
				# Do locosys full cold start
				echo -e "\$PMTK104*37\r\n" > $GPSPORT
			elif [[ $GPSMODULE == 'quectel' ]]; then
				stopGPS
				send_at_command "at+qgpsdel=0"
				read_at_result "at+qgpsdel=0"
				startGPS
			fi
			sleep 1
			$TOOLPATH/gpstest $GPSPORT $GPSMODULE info
		else
			echo "Error: Baud rate is $current_baudrate"
		fi
	;;
	'start')
		if [ ! -z "$2" ] && [ ! -z "$3" ]
		then
			GPSPORT=$2
			GPSMODULE=$3
			echo "GPSPORT is $GPSPORT, Module is $GPSMODULE"
		else
			help
			exit
		fi
		stty -F $GPSPORT 9600
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == '9600' ]]; then
			startGPS
		else
			echo "Error: Baud rate is $current_baudrate"
		fi
	;;
	'stop')
		if [ ! -z "$2" ] && [ ! -z "$3" ]
		then
			GPSPORT=$2
			GPSMODULE=$3
			echo "GPSPORT is $GPSPORT, Module is $GPSMODULE"
		else
			help
			exit
		fi
		stty -F $GPSPORT 9600
		current_baudrate=`stty -F $GPSPORT -a | grep speed | awk -F " " '{print $2}'`
		if [[ $current_baudrate == '9600' ]]; then
			stopGPS
		else
			echo "Error: Baud rate is $current_baudrate"
		fi
	;;
    *)
		help
    ;;
esac
