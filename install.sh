#!/bin/bash

install_dir="$HOME/.lazurite/writer"
env_file="env.txt"
rule_file="99-lazurite-writer.rules"

#make directory and copy files
mkdir -p $install_dir
cp -r * $install_dir
cd $install_dir

#make environment variable
uname=`uname -r`
echo "lib_path=\"/lib/modules/$uname/kernel/drivers/usb/serial\"" > $env_file

#install xmodem
sudo apt install lrzsz

#make rule file
echo "ACTION==\"add\", SUBSYSTEM==\"tty\", KERNEL==\"tty*\", ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6001\", ATTRS{product}==\"LAZURITE*\", RUN+=\"/bin/bash -c 'cd $install_dir; ./write.sh %k'\"" > $rule_file
echo "ACTION==\"remove\", ENV{DEVNAME}==\"/dev/ttyUSB*\", ENV{ID_MODEL}==\"LAZURITE*\", RUN+=\"/bin/bash -c 'cd $install_dir; ./unlock.sh %k'\"" >> $rule_file

#locate udev rules
sudo cp $rule_file /etc/udev/rules.d/

echo ""
echo "You need to install FTDI library as following."
echo "(how to install might be changed by FTDI)"
echo -e "\tdownload FTDI library and copy to $install_dir/ftdi folder"
echo -e "\tsudo cp $install_dir/ftdi/build/* /usr/local/lib/"
echo -e "\tcd /usr/local/lib/"
echo -e "\tsudo ln -s libftd2xx.so.1.x.x libftd2xx.so"
echo -e "\tcd $install_dir/bootmode; make"
echo -e "\tcd $install_dir/reset; make"
echo -e "\treboot"
