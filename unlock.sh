#!/bin/bash

log_file="unlock.log"

if [ $# -ne 1 ]; then
	echo [`date "+%h %d %H:%M:%S"`] invalid argument >> $log_file
	exit
fi

ttyx=$1
lock_file=".$ttyx.lock"

if [ -e $lock_file ]; then
	cmd="grep PRODUCT= /sys/bus/usb-serial/devices/$ttyx/../uevent > /dev/null 2>&1"
	eval $cmd
	if [ $? -eq 2 ]; then		# if unplugged, exit status will be 2
		rm $lock_file
	fi
fi
