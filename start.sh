#!/bin/bash

NAME=$1
qemu-system-x86_64 -enable-kvm $NAME -nographic -net nic -net tap,ifname=mybr0

