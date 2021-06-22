#!/bin/bash

GET_INPUT="i2cget -y 2 0x20 0x09"

echo "init the gpio direction"
i2cset -y 2 0x20 0 0x0f

i=0
while true
do
	echo "=========== $i loop ============="
	
	echo "Set GPIO[7:4] gpio values to high"
	i2cset -y 2 0x20 0x0a 0xf0
	sleep 1
	
	input_value=$(( $(eval $GET_INPUT) & 0x0f ))
	echo "Read GPIO[3:0] input values: $input_value"
	if [[ $input_value -ne 0x0f ]]; then
		echo "Error: GPIO[3:0] input values are not high"
		exit 1
	fi
	
	echo "Set GPIO[7:4] gpio values to low"
	i2cset -y 2 0x20 0x0a 0
	sleep 1
	
	input_value=$(( $(eval $GET_INPUT) & 0x0f ))
	echo "Read GPIO[3:0] input values: $input_value"
	if [ $input_value -ne 0 ]; then
		echo "Error: GPIO[3:0] input values are not low"
		exit 1
	fi
	
	i=$(($i+1))
done
