#!/bin/bash -x

# Configuration!
SSHKEY="$(cat ~/.ssh/authorized_keys)"
ROOTPASSWD=root
FSSIZE=1G

# Precise
#MIRROR=http://archive.ubuntu.com/ubuntu/
MIRROR=http://mirror.internode.on.net/pub/ubuntu/ubuntu/
DIST=precise
KERNEL=3.2.0-23-virtual
INTERFACE=eth0

PYTHON=no

############################

[ -d resources ] || mkdir resources
pushd resources

# cache bootstrap files locally
[ ! -d $DIST ] && debootstrap $DIST $DIST/ $MIRROR

# create image
# rm fs.img
# dd if=/dev/zero of=fs.img bs=$FSSIZE count=1 || exit

rm fs.qcow2
qemu-img create -f qcow2 fs.qcow2 10G || exit

modprobe nbd max_part=16 || exit

qemu-nbd -c /dev/nbd0    fs.qcow2     || exit

fdisk /dev/nbd0 << EOF
n
p
1
2048

a
p
w
EOF

# qemu-nbd -d /dev
#exit

# should alias the devices

partprobe /dev/nbd0 || exit

#losetup -f fs.img /dev/nbd0 || exit
#losetup -f fs.img -o $((2048 * 512)) /dev/nbd0p1 || exit


# mount loop device and copy files
mkfs.ext4 /dev/nbd0p1 || exit

# grab filesystem uuid
UUID=$( blkid -p -s UUID  /dev/nbd0p1 | sed 's/.*="\([^"]*\).*/\1/' )

rm -rf mnt && mkdir mnt || exit
mount /dev/nbd0p1 mnt || exit

cp -rp $DIST/* mnt || exit



# mount systems and chroot
pushd mnt
for i in /proc /sys /dev; do mount -B $i .$i; done || exit


############################

# install kernel, boot config, ssh etc
chroot . <<- EOF

# the extlinux package comes from the universe repo in ubuntu/precise
cat > /etc/apt/sources.list <<- EOF2
deb http://mirror.internode.on.net/pub/ubuntu/ubuntu/ precise main
deb http://mirror.internode.on.net/pub/ubuntu/ubuntu/ precise universe
EOF2

# Ubuntu keys
apt-key update
apt-get update

# Install kernel
apt-get -y install linux-image-$KERNEL

apt-get -y install extlinux
mkdir -p /boot/syslinux
extlinux --install /boot/syslinux

# fix mbr in case grub tried to overwrite it
dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr.bin of=/dev/nbd0

cat > /boot/syslinux/syslinux.cfg <<- EOF2
CONSOLE 0
SERIAL 0 115200 0
DEFAULT linux
PROMPT 0
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL /boot/vmlinuz-$KERNEL
  APPEND rw root=UUID=$UUID initrd=/boot/initrd.img-$KERNEL vga=normal fb=false console=ttyS0,115200n8
EOF2


# spawn shell on console
# http://www.jaredlog.com/?p=1484
# https://help.ubuntu.com/community/KVM/Access
cat > /etc/init/ttyS0.conf <<- EOF2
start on stopped rc RUNLEVEL=[2345] and (
            not-container or
            container CONTAINER=lxc or
            container CONTAINER=lxc-libvirt)

stop on runlevel [!2345]

respawn
exec /sbin/getty -8 115200 ttyS0 xterm
EOF2


# set up network
cat > /etc/network/interfaces << EOF2
auto lo
iface lo inet loopback

auto $INTERFACE
iface $INTERFACE inet dhcp
EOF2

# root passwd
if [ -n "$ROOTPASSWD" ]; then
  echo root:$ROOTPASSWD | chpasswd
fi

# ssh keys
if [ -n "$SSHKEY" ]; then
  apt-get -y install ssh
  mkdir /root/.ssh
  echo "$SSHKEY" > /root/.ssh/authorized_keys
  chmod 400 /root/.ssh/authorized_keys
  sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
fi

# python
if [ $PYTHON = "yes" ]; then
  apt-get -y install python2.7
  ln -s /usr/bin/python2.7 /usr/bin/python
fi
EOF

############################

# unmount everything
for i in /proc /sys /dev; do umount .$i; done
popd

umount -l mnt || exit
sleep 2

qemu-nbd -d /dev/nbd0p1
qemu-nbd -d /dev/nbd0  
#losetup -D
rmdir mnt

chmod 666 fs.qcow2
cp fs.qcow2 "$DIST-$KERNEL.qcow2"
chmod 666 "$DIST-$KERNEL.qcow2"


popd # resources

