#!/bin/bash

# OK. with overlays we can inject - project/working dirs, or even /home/meteo or  pem files etc. 

if [ -z "$1" ]; then
   # echo "usage $0 <path to image> <optional mac-address> "
   echo "usage $0 <path to chroot> "
   exit 1
fi


# mac address 
systemd-nspawn \
  -D "$1" \
  --overlay="/home/meteo/minimal-alpine-haskell-beanstalk:/home/meteo/minimal-alpine-haskell-beanstalk"  \
  --boot \
  --network-bridge=br0 -n


