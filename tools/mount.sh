#!/bin/bash
# mounts the image in ./build/mnt

if [ -z "$1" ]; then
   echo "usage $0 <image>" 
   exit 1
fi

if [ $( mount | grep -c loop ) != 0 ] ; then
   echo "loop device already in use"
   exit 1
fi


target=$1
mnt="./build/mnt"

set -x

losetup -f $target /dev/loop0 || exit
losetup -f $target -o $((2048 * 512)) /dev/loop1 || exit

[ -d "$mnt" ] || mkdir "$mnt"
mount /dev/loop1 "$mnt" || exit

# mount systems
for i in /proc /sys /dev; do
  mount -B $i "$mnt/$i";
done || exit




# pushd mnt || exit
# for i in /proc /sys /dev; do mount -B $i .$i; done || exit


#popd # mnt
# popd # build
