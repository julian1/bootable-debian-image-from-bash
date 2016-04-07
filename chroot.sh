#!/bin/bash -x

pushd resources

losetup -f fs.img /dev/loop0 || exit
losetup -f fs.img -o $((2048 * 512)) /dev/loop1 || exit

[ -d mnt ] || mkdir mnt
mount /dev/loop1 mnt || exit

pushd mnt || exit
  
for i in /proc /sys /dev; do mount -B $i .$i; done || exit


chroot .

echo "done"


for i in /proc /sys /dev; do umount .$i; done

popd

umount mnt
losetup -D

# shouldn't be needed
umount /dev/loop1
umount /dev/loop0



#popd
