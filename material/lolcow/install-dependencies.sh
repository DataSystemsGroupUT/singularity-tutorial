#!/bin/sh

#sed -i 's/$/ universe/' /etc/apt/sources.list
apt-get update
apt-get -y install fortune cowsay lolcat
apt-get clean
