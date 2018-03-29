#!/bin/bash


############################
# Configuration!

# if [ -z "$KEYS" ]; then...
KEYS="$(cat /home/meteo/.ssh/authorized_keys)"
# DANGEROUS - edit me!
ROOTPASSWD=root
FSSIZE=1G
# MIRROR=http://mirror.internode.on.net/pub/debian/
MIRROR=http://ftp.us.debian.org/debian/
DIST=stretch
KERNEL=4.9.0-6-amd64
PYTHON=yes

# Jessie
# DIST=jessie
# KERNEL=3.16.0-4-amd64


############################
# sanity

if [[ $EUID -ne 0 ]]; then
   # also, require root for correct debootstrap dir permissions.
   echo "Must be root for mount/losetup"
   exit 1
fi

if [ $( mount | grep -c loop ) != 0 ] ; then
   echo "loop device already in use"
   exit 1
fi

if [ -z "$KEYS" ]; then
  echo "Need ssh keys!"
  exit 1
fi

if [ "$ROOTPASSWD" = "root" ]; then
  echo "WARNING change the root password!"
  # exit 1
fi


############################
# debootstrap download and cache

# log
set -x

# fail fast
set -e

[ -d ./cache ] || mkdir ./cache
[ -d ./build ] || mkdir ./build

cache="./cache/$DIST"
target="./build/$DIST-$KERNEL.img"
mnt="./mnt"


# delete stale cache. eg. 1 day.
if [ -d "$cache" ]; then
  now=$(date +%s)
  file=$(stat -c %Y "$cache")
  if [ $now -gt $(( $file + 86400 )) ]; then
    echo "deleting stale cache!"
    rm -rf "$cache"
  else
    echo "cache ok!"
  fi
fi


# download bootstrap files locally. note use || exit
[ -d "$cache" ] || debootstrap "$DIST" "$cache/" $MIRROR


############################
# create image

rm $target  || true
rm -rf "$mnt" || true
mkdir "$mnt"

# image
dd if=/dev/zero of=$target bs=$FSSIZE count=1

chmod 666 $target

# partition
fdisk $target << EOF
n
p
1
2048

a
p
w
EOF


############################
# initial filesystem

cleanup_resources () {
  # TODO chaining resource cleanup see, https://stackoverflow.com/questions/3338030/multiple-bash-traps-for-the-same-signal
  # don't fail fast, during cleanup
  set +e

  for i in /proc /sys /dev; do
    umount "$mnt/$i";
  done

  umount "$mnt"
  losetup -D
  rmdir "$mnt"
}

trap cleanup_resources EXIT


losetup -f $target /dev/loop0
losetup -f $target -o $((2048 * 512)) /dev/loop1


# mkfs
mkfs.ext4 /dev/loop1

# grab filesystem uuid for later
UUID=$( blkid -p -s UUID /dev/loop1 | sed 's/.*="\([^"]*\).*/\1/' )


# mount  the device
mount /dev/loop1 "$mnt"

# copy debootstrap
cp -rp $cache/* "$mnt"


############################
# install kernel, and configure

# mount systems
for i in /proc /sys /dev; do
  mount -B $i "$mnt/$i";
done

# discover kernel version...
# KERNEL=$( apt-cache search linux-image | cut -d ' ' -f 1 | egrep '^linux-image-[0-9\.-]{5,}amd64$' | sed 's/linux-image-\(.*\)/\1/' )

# chroot and install kernel, boot config, ssh
chroot --userspec=0:0 "$mnt" <<- EOF

# fail fast
set -e

# Install kernel
apt-get -y install linux-image-$KERNEL

apt-get -y install extlinux
mkdir -p /boot/syslinux
extlinux --install /boot/syslinux
dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/loop0

cat > /boot/syslinux/syslinux.cfg <<- EOF2
CONSOLE 0
SERIAL 0 115200 0
DEFAULT linux
PROMPT 0
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL /boot/vmlinuz-$KERNEL
  APPEND rw root=UUID=$UUID initrd=/boot/initrd.img-$KERNEL vga=normal fb=false console=ttyS0,115200n8 net.ifnames=0 biosdevname=0
EOF2

cat > /etc/network/interfaces << EOF2
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF2

if [ -n "$ROOTPASSWD" ]; then
  echo root:$ROOTPASSWD | chpasswd
fi

if [ -n "$KEYS" ]; then
  apt-get -y install ssh
  mkdir /root/.ssh
  echo "$KEYS" > /root/.ssh/authorized_keys
  chmod 400 /root/.ssh/authorized_keys
  sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
fi

if [ $PYTHON = "yes" ]; then
  apt-get -y install python-minimal
fi
EOF

