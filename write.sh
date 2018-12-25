#!/bin/bash

csv_file="config.csv"
log_file="write.log"
target="LAZURITE mini series"
dev_name=${ID_MODEL_ENC//\\x20/ }
uname=`uname -r`
lib_path="/lib/modules/$uname/kernel/drivers/usb/serial"

date_echo() {
	echo [`date "+%h %d %H:%M:%S"`] $1 >> $log_file
}

exec_cmd () {
	eval $1
	result_code=$?
	if [ $2 ] && [ $result_code -ne 0 ]; then
		date_echo "error: '$1' command returns '$result_code'."
		exit
	fi
}

# Check arugments
if [ $# -ne 1 ]; then
	date_echo 'invalid argument.'
	exit
fi

ttyx=$1
tty_file="/dev/$ttyx"
lock_file=".$ttyx.lock"

# Check target device and lock file
if [[ $dev_name != $target ]] || [ -e $lock_file ]; then
	exit
fi

# Create lock file in order to prevent from re-running this script
touch $lock_file

# Read subghz short address from device and check if valid or not
#
# ('test920j' program shall be written as factory default)
#  step:
#   1) reset device
#   2) set baudrate
#   3) receive
#        '115200'
#        'Welcome'
#   4) send 'sgi'
#   5) receive 'sgi'
#   6) send 'sggma'
#   7) receive 'sggma,0x????' <- subghz address
#
# [Note]
#   If device is not return subghz address within 3 second, timeout
#   occures and default program (if specified in csv file as address
#   0xFFFF) will be written.
#
exec_cmd "rmmod ftdi_sio" false
exec_cmd "rmmod usbserial" false
# step1
exec_cmd "reset/reset \"$dev_name\"" true
exec_cmd "insmod $lib_path/usbserial.ko" true
exec_cmd "insmod $lib_path/ftdi_sio.ko" true
# step2
exec_cmd "stty -F $tty_file 115200 -echo" true
start_time=`date +%s`
while IFS= read -t 3 line; do
#	date_echo $line
#: <<'END'
	# check timeout
	if [[ `date +%s`-$start_time -gt 3 ]]; then
		break
	fi
	# step3
	if [ $line == "Welcome" ]; then
		# step4
		sleep 0.1
		echo "sgi" > $tty_file
		continue
	fi
	# step5
	if [ $line = "sgi" ]; then
		# step6
		sleep 0.1
		echo "sggma" > $tty_file
		continue
	fi
	# step7
	if [[ $line =~ sggma,0x[0-9a-fA-F]{4}$ ]]; then
		dev_addr=${line:6:6} # zero-based index 6, length 6
		break
	fi
	# reserved for factory-iot
	if [[ $line =~ ^0x[0-9a-fA-F]{4}$ ]]; then
		dev_addr=$line
		break
	fi
#END
done < $tty_file

# If address is not found, then assign address 0xFFFF
if [ -z "$dev_addr" ]; then
	addr='0xFFFF'
else
	addr=$dev_addr
fi

# Load csv file and check if program file is exist
while IFS=, read key val; do
	if [ "${addr,,}" == "${key,,}" ]; then
		program_path=$val
	fi
done < $csv_file
if [ -z "$program_path" ] || [ ! -f $program_path ] ; then
	date_echo "error: cannot find program to write for $addr."
	exit
fi

# Execute writing program
exec_cmd "rmmod ftdi_sio" false
exec_cmd "rmmod usbserial" false
exec_cmd "bootmode/bootmode \"$dev_name\"" true
exec_cmd "insmod $lib_path/usbserial.ko" true
exec_cmd "insmod $lib_path/ftdi_sio.ko" true
exec_cmd "stty -F $tty_file 115200" true
exec_cmd "sx -b $program_path > $tty_file < $tty_file 2> /dev/null" true

# Reset device
exec_cmd "rmmod ftdi_sio" false
exec_cmd "rmmod usbserial" false
exec_cmd "reset/reset \"$dev_name\"" true
exec_cmd "insmod $lib_path/usbserial.ko" true
exec_cmd "insmod $lib_path/ftdi_sio.ko" true
