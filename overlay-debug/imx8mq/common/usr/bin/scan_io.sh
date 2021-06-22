#!/bin/bash

LOG_PATH=/var/log/system_test
mkdir -p $LOG_PATH
LOG=${LOG_PATH}/exist_io
USB=${LOG_PATH}/exist_usb
PCI=${LOG_PATH}/exist_pci
rm -rf ${LOG_PATH}/*

scan_cpu()
{
	result=`nproc`
	if [ -n "$result" ]; then
		echo "$1 $result" >> $LOG
	fi
}

scan_ddr()
{
	result=`free | grep Mem | awk '{print $2}'`
	if [ -n "$result" ]; then
		echo "$1 $result" >> $LOG
	fi
}

scan_iface()
{
	result=`ifconfig | grep $1`
	if [ -n "$result" ]; then
		echo $1 >> $LOG
	fi
}

scan_blk()
{
	result=`lsblk | grep $2`
	if [ -n "$result" ]; then
		echo $1 >> $LOG
	fi
}

scan_usb()
{
	result=`lsusb | awk '{print $6}' | sudo tee $USB`
	if [ -n "$result" ]; then
		echo $1 >> $LOG
	fi
}

scan_pci()
{
	result=`lspci | sudo tee $PCI`
	if [ -n "$result" ]; then
		echo $1 >> $LOG
	fi
}

scan_mcu()
{
	result=`system_test | grep version | awk '{print $5}'`
	if [ -n "$result" ]; then
		echo "$1 $result" >> $LOG
	fi
}

scan_cpu cpu
scan_ddr ddr
scan_blk emmc mmcblk0
scan_blk sd mmcblk1
scan_iface eth0
scan_iface eth1
scan_iface wlan0
scan_iface can0
scan_iface can1
scan_usb usb
scan_pci pci
scan_mcu mcu
