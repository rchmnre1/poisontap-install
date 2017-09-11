#!/bin/bash
# poisontap-srv-install.sh

cd ~/

# elevate privileges to root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

apt-get -y install git npm curl screen sudo

npm install websocket
curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
apt-get -y install nodejs
git clone https://github.com/samyk/poisontap
cd poisontap
screen -dm "node backend_server.js &"

apt-get -y install open-vm-tools
