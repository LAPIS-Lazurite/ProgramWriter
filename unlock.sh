#!/bin/bash

log_file="unlock.log"

if [ $# -ne 1 ]; then
	echo [`date +%s`] invalid argument > $log_file
	exit
fi

ttyx=$1
lock_file=".$ttyx.lock"

if [ -e $lock_file ]; then
	cmd="grep PRODUCT= /sys/bus/usb-serial/devices/$ttyx/../uevent"
	eval $cmd
	if [ $? -eq 2 ]; then		# if unplugged, exit status will be 2
		rm $lock_file
	fi
fi
