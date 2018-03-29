#!/bin/bash


if [ -z "$1" ]; then
   # echo "usage $0 <path to image> <optional mac-address> "
   echo "usage $0 <path to chroot> "
   exit 1
fi


# mac address 
systemd-nspawn \
  -D "$1" \
  --boot \
  --network-bridge=br0 -n


