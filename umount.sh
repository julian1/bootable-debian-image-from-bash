#!/bin/bash -x

pushd mnt
for i in /proc /sys /dev; do umount .$i; done
popd
umount mnt
losetup -D

