#!/bin/bash

# assumes have bridge br
# apt-get install qemu-system-x86-64

IMAGE=$1
PID=$$
MAC='00:01:04:1b:2C:1B'

if [ -z "$1" ]; then
   echo "usage $0 <path to image>" 
   exit 1
fi


qemu-system-x86_64 \
  -enable-kvm \
  -drive format=raw,file=./$IMAGE \
  -nographic \
  -net nic,macaddr=$MAC \
  -net tap,ifname=mybr$PID


# just console out
#  -nographic \

#  -drive file=./$IMAGE \
#  -drive format=raw,file=./$IMAGE \
