#!/bin/bash -x

mnt="./mnt"

set -x

for i in /proc /sys /dev; do
  umount "$mnt/$i";
done

umount "$mnt"
losetup -D
rmdir "$mnt"


# pushd build
# pushd mnt

# for i in /proc /sys /dev; do umount .$i; done
# popd # mnt
# umount mnt
# losetup -D

# popd # build

