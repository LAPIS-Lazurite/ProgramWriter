#!/bin/bash

database="$HOME/foo/bar.sqlite3"
program_root="$HOME/foo/baz"
log_file="./write.log"
tty_file="/dev/ttyUSB0"
dev_name="LAZURITE mini series"
uname=`uname -r`
lib_path="/lib/modules/$uname/kernel/drivers/usb/serial"

date_echo() {
	echo [`date "+%h %d %H:%M:%S"`] $1 >> $log_file
}

exec_cmd () {
	cmd="sudo $1"
	eval $cmd
	result_code=$?
	if [ $2 ] && [ $result_code -ne 0 ]; then
		date_echo "error: '$cmd' command returns '$result_code'."
		exit
	fi
}

echo === choose program number ===
sensors=$(sqlite3 $database 'SELECT * FROM sensor')
if [ $? -ne 0 ]; then
		date_echo "error: sqlite3 returns $?."
	exit
fi
data=()
while read line; do
	IFS='|' read -ra arr <<< $line
	index=${arr[0]}
	sensor_data[index]=${arr[6]##*/}
	#echo ${arr[0]} : ${arr[1]}_${arr[2]} ${data[index]}
	echo ${arr[0]}: ${arr[1]}_${arr[2]} ${arr[3]}
done <<END
$sensors
END

while read ANS; do
	if [[ "$ANS" =~ ^[0-9]+$ ]]; then
		index=$ANS
		break
	fi
done
filename=${sensor_data[index]}
program_path=$program_root/$filename
echo "program: " $program_path

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
