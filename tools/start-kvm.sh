#!/bin/bash

# assumes bridge br0 is configured,
# apt-get install qemu-system-x86-64

IMAGE=$1
PID=$$

if [ -z "$1" ]; then
   echo "usage $0 <path to image> <optional mac-address> "
   exit 1
fi


# pass mac argument by argument to avoid different scripts. mac should come from dhcp configuration.
if [ -z "$2" ]; then
  MAC='00:01:04:1b:2C:1B'
else
  MAC="$2"
fi

echo "mac is $MAC"


qemu-system-x86_64 \
  -enable-kvm \
  -drive format=raw,file=./$IMAGE \
  -nographic \
  -net nic,macaddr="$MAC" \
  -net tap,ifname=mybr$PID


# just console out
#  -nographic \

#  -drive file=./$IMAGE \
#  -drive format=raw,file=./$IMAGE \
