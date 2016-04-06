#!/bin/bash -x

pushd resources

pushd mnt

for i in /proc /sys /dev; do umount .$i; done

popd

umount mnt
losetup -D

# shouldn't be needed
umount /dev/loop1
umount /dev/loop0

