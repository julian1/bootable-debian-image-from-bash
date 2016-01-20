#!/bin/bash -x

cd mnt
for i in /proc /sys /dev; do umount .$i; done
cd ..
umount mnt
losetup -D

