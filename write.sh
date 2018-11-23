#!/bin/bash

. ./env.txt
. ./data/config.txt
log_file="write.log"
dev_name=${ID_MODEL_ENC//\\x20/ }

if [ $# -ne 1 ]; then
	echo [`date +%s`] invalid argument > $log_file
	exit
fi

ttyx=$1
dev_file="/dev/$ttyx"
lock_file=".$ttyx.lock"

if [[ $target != $dev_name ]] || [ -e $lock_file ]; then
	exit
fi

touch $lock_file

exec_cmd () {
	eval $1
	if [ $2 -a $? -ne 0 ]; then
		result_code=$?
		echo  [`date +%s`] error: \'$1\' returns \'$result_code\' >> $log_file
		exit
	fi
}

exec_cmd "rmmod ftdi_sio" false
exec_cmd "rmmod usbserial" false
exec_cmd "bootmode/bootmode \"$dev_name\"" true
exec_cmd "insmod $lib_path/usbserial.ko" true
exec_cmd "insmod $lib_path/ftdi_sio.ko" true
exec_cmd "stty -F $dev_file 115200" true
exec_cmd "sx -b $program > $dev_file < $dev_file" true

