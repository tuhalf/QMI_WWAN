#!/bin/bash

: '
QMI installation script by Sixfab
This script is strictly for Raspberry Pi OS.

Created By Metin Koc, Nov 2018
Maintainers: Saeed Johar, Yasin Kaya
'
# Text colors
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
SET='\033[0m'

# Directories
INS_DIR=/opt/qmi_files                      # New directory
OLD_DIR=/home/$(whoami)/files/quectel-CM    # Old directory
# UDHCPC_DIR=/etc/udhcpc                      # For RPi OS
UDHCPC_DIR=/usr/share/udhcpc              # For Ubuntu OS
MOD_DIR=/etc/modules-load.d/modules.conf    # For adding(modprobe) qmi_wwan_q  

# service names
service_reconnect=qmi_reconnect.service
service_ModemManager=ModemManager

# clean old installation 
status_reconnect="$(systemctl is-active $service_reconnect)"
if [ "$status" = "active" ]; then 
    systemctl stop $service_reconnect
    systemctl disable $service_reconnect
fi

if [ -d "$OLD_DIR" ]; then rm -rf /home/$(whoami)/files ; fi # for old directory
if [ -d "$INS_DIR" ]; then rm -rf $INS_DIR; fi

# Installations
echo -e "${YELLOW}Installing kernel headers for Raspberry Pi${SET}"
# apt install raspberrypi-kernel-headers
# For ubuntu it should be 
apt install linux-headers-$(uname -r)

echo -e "${YELLOW}Installing udhcpc${SET}"
apt install udhcpc

# Download and isntall resources
echo -e "${YELLOW}Create and Change directory to $INS_DIR ${SET}"
mkdir -p $INS_DIR &&
pushd $INS_DIR

case $(uname -r) in
    4.14*) echo $(uname -r) based kernel found
        echo "${YELLOW}Downloading source files${SET}"
        wget https://raw.githubusercontent.com/tuhalf/QMI_WWAN/main/4.14.all.zip -O drivers.zip 
        unzip drivers.zip -d $INS_DIR && rm -r drivers.zip;;
esac
mkdir /lib/modules/4.14.98-imx/kernel/drivers/usb/serial/
echo -e "${YELLOW}Change directory to $INS_DIR/drivers${SET}"
if [ -d "$INS_DIR/drivers" ];then
    pushd $INS_DIR/drivers
    make && make install
    popd
fi


echo -e "${YELLOW}Downloading Connection Manager${SET}"
wget https://github.com/sixfab/Sixfab_QMI_Installer/raw/main/src/Quectel_QConnectManager_Linux_V1.6.1.zip -O quectel-CM.zip
unzip quectel-CM.zip -d $INS_DIR && rm quectel-CM.zip

echo -e "${YELLOW}Copying udhcpc default script${SET}"
chmod +x $INS_DIR/quectel-CM/default.script
if [ -d "$UDHCPC_DIR" ]; 
    then cp $INS_DIR/quectel-CM/default.script $UDHCPC_DIR; 
    else echo "$UDHCPC_DIR doesn't exist"      
fi

echo -e "${YELLOW}Making $INS_DIR/quectel-CM${SET}"
pushd $INS_DIR/quectel-CM
make
popd

if ! (grep -q "qmi_wwan_q" $MOD_DIR ); then
	echo "qmi_wwan_q" >> $MOD_DIR;
fi

# If ModemManager is installed and running, stop it as it will interfere the cmtool
status_modemmanager="$(systemctl is-active $service_ModemManager)"
if [ "$status_modemmanager" = "active" ]; then 
    systemctl stop $service_ModemManager
    systemctl disable $service_ModemManager
fi

echo -e "${YELLOW}After reboot please follow commands mentioned below${SET}"
echo -e "${YELLOW}go to $INS_DIR/quectel-CM and run ${GREEN}sudo ./quectel-CM -s [YOUR APN]${SET} ${YELLOW} for manual operation${SET}"

read -p "Press ENTER key to reboot" ENTER
reboot
