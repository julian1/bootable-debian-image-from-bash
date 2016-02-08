#!/bin/bash

NAME=$1

PID=$$

MAC='00:01:04:1b:2C:1B'

qemu-system-x86_64 \
  -enable-kvm \
  -nographic \
  -drive format=raw,file=./$NAME \
  -net nic,macaddr=$MAC \
  -net tap,ifname=mybr$PID

