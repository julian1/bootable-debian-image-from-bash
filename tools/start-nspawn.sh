#!/bin/bash


# mac address 
systemd-nspawn \
  -D ./build/stretch.chroot/ \
  --boot \
  --network-bridge=br0 -n


