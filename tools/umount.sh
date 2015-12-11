#!/bin/bash -x

for i in ./mnt/proc ./mnt/sys ./mnt/dev; do umount .$i; done

umount mnt

losetup -D

