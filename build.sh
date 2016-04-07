#!/bin/bash -x

# Configuration!
SSHKEY="$(cat ~/.ssh/authorized_keys)"
ROOTPASSWD=root
FSSIZE=1G

#MIRROR=http://mirror.internode.on.net/pub/debian/
# DIST=jessie
#KERNEL=4.3.0-1-amd64
# INTERFACE=ens3

# Precise
#MIRROR=http://archive.ubuntu.com/ubuntu/
MIRROR=http://mirror.internode.on.net/pub/ubuntu/ubuntu/
DIST=precise
KERNEL=3.2.0-23-virtual
INTERFACE=eth0
CONSOLE=true

PYTHON=no

############################

[ -d resources ] || mkdir resources
pushd resources

# cache bootstrap files locally
[ ! -d $DIST ] && debootstrap $DIST $DIST/ $MIRROR

# create image
rm fs.img
dd if=/dev/zero of=fs.img bs=$FSSIZE count=1 || exit

fdisk fs.img << EOF
n
p
1
2048

a
p
w
EOF

losetup -f fs.img /dev/loop0 || exit
losetup -f fs.img -o $((2048 * 512)) /dev/loop1 || exit


# mount loop device and copy files
mkfs.ext4 /dev/loop1 || exit

# grab filesystem uuid
UUID=$( blkid -p -s UUID  /dev/loop1 | sed 's/.*="\([^"]*\).*/\1/' )

rm -rf mnt && mkdir mnt || exit
mount /dev/loop1 mnt || exit

cp -rp $DIST/* mnt || exit

# mount systems and chroot
pushd mnt
for i in /proc /sys /dev; do mount -B $i .$i; done || exit

# CONSOLE 0
# SERIAL 0 115200 0
# APPEND rw root=UUID=$UUID initrd=/boot/initrd.img-$KERNEL acpi=off
# APPEND rw root=UUID=$UUID initrd=/boot/initrd.img-$KERNEL vga=normal fb=false console=ttyS0,115200n8

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

# fix mbr in case grub tried to overwrite it
dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr.bin of=/dev/loop0


# Install ext/syslinux
# http://shallowsky.com/linux/extlinux.html
# apt-get -y install syslinux

# deleted this
#apt-get -y install extlinux
#mkdir -p /boot/syslinux
#extlinux --install /boot/syslinux


apt-get -y install extlinux
extlinux --install /boot/


# Note, precise will prompt about grub, considered a bug, and workaround is too complicated.
# http://askubuntu.com/questions/146921/how-do-i-apt-get-y-dist-upgrade-without-a-grub-config-prompt


# cat > /boot/syslinux/syslinux.cfg <<- EOF2
# ext/syslinux boot config

cat > /boot/extlinux/extlinux.conf <<- EOF2
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

allow-hotplug $INTERFACE
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
umount mnt
losetup -D
rmdir mnt

chmod 666 fs.img

# leave fs.img where it is, so that can use remount easily with mount.sh
#cp fs.img "$DIST-$KERNEL.img"
#chmod 666 "$DIST-$KERNEL.img"

# Could neat to make a COW image as well?

# make a virtualbox image if we can
# rm fs.vdi
# which VBoxManage && VBoxManage convertfromraw --format VDI fs.img fs.vdi && chmod 666 fs.vdi

popd # resources

