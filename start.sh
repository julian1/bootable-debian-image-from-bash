#!/bin/bash

NAME=$1
qemu-system-x86_64 \
  -enable-kvm \
  -nographic \
  -drive format=raw,file=./$NAME  \
  -net nic -net tap,ifname=mybr0

