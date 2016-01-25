#!/bin/bash -x

# Editable configuration!
SSHKEY="$(cat /home/meteo/.ssh/id_rsa.pub)"
# ROOTPASSWD=root
FSSIZE=1G
# CONSOLE or VGA
CONSOLE=false
# install minimal python, useful for ansible etc
PYTHON=false
# Mirror to use
MIRROR=http://mirror.internode.on.net/pub/debian/

############################

# cache bootstrap files locally
[ ! -d jessie ] && debootstrap jessie jessie/ $MIRROR

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


[ -d mnt ] || mkdir mnt
mount /dev/loop1 mnt || exit
ls mnt

cp -rp jessie/* mnt || exit

# mount systems and chroot
cd mnt
for i in /proc /sys /dev; do mount -B $i .$i; done || exit

# install kernel, boot config, ssh
chroot . <<- EOF
apt-get -y install linux-image-3.16.0-4-amd64
apt-get -y install syslinux
apt-get -y install extlinux
mkdir -p /boot/syslinux
extlinux --install /boot/syslinux
dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/loop0
[ $ROOTPASSWD ] && echo root:$ROOTPASSWD | chpasswd
apt-get -y install ssh
mkdir /root/.ssh
echo $SSHKEY > /root/.ssh/authorized_keys
chmod 400 /root/.ssh/authorized_keys
EOF

# python
if [ $PYTHON = "true" ]; then
chroot . <<- EOF
apt-get -y install python2.7
ln -s /usr/bin/python2.7 /usr/bin/python
EOF
fi


# syslinux boot configuration
# the indenting around if/else is needed
if [ $CONSOLE = "true" ]; then
cat > ./boot/syslinux/syslinux.cfg <<- EOF
CONSOLE 0
SERIAL 0 115200 0

DEFAULT linux
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL ../vmlinuz-3.16.0-4-amd64
  APPEND rw root=UUID=$UUID initrd=../initrd.img-3.16.0-4-amd64 vga=normal fb=false console=ttyS0,115200n8
EOF
else
cat > ./boot/syslinux/syslinux.cfg <<- EOF
DEFAULT linux
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL ../vmlinuz-3.16.0-4-amd64
  APPEND rw root=UUID=$UUID initrd=../initrd.img-3.16.0-4-amd64
EOF
fi

# network interfaces
cat > ./etc/network/interfaces << EOF
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
EOF

# allow root ssh
sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' ./etc/ssh/sshd_config

# unmount everythiing
for i in /proc /sys /dev; do umount .$i; done
cd ..
umount mnt
losetup -D

# also make a virtualbox image if we can
# rm fs.vdi
# which VBoxManage && VBoxManage convertfromraw --format VDI fs.img fs.vdi && chmod 666 fs.vdi

