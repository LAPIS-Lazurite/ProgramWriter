# ProgramWriter
Easy Lazurite program writer environment for Linux

## Description
If you need to write same program to many Lazurite nodes, this tool will help you. After you install this tool to a host Linux device, it will write program by just hot-pluging Lazurite node to the host.

## Installation
1. run installer

       ./install.sh

2. install FTDI library

       download FTDI library and copy to $install_dir/ftdi folder
       sudo cp $install_dir/ftdi/build/* /usr/local/lib/
       cd /usr/local/lib/
       sudo ln -s libftd2xx.so.1.x.x libftd2xx.so
       cd $install_dir/bootmode; make
       cd $install_dir/reset; make


3. if you use this on raspbian os, run 'crontab -e' and input below command.

       @reboot sudo systemctl restart systemd-udevd; sudo systemctl daemon-reload

4. you can specify target and program name in $install_dir/data/config.txt file.

## Uninstallation
1. delete FTDI library in /usr/local/lib, if necessary
2. delete rule file in /etc/udev/rules.d
3. remove description of "crontab -e", if you input
4. delete all files in $install_dir


#### the default location $install_dir is "~/.lazurite/writer".
