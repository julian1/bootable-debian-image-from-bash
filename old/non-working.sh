#!/bin/bash -x

# Must be run as root
# More a template, than parameter driven script.

SSHKEYS="$(cat /home/$USER/.ssh/id_rsa.pub)"
# For creating a rescue disk and debug
ROOTPASSWD=root
# Filesystem image size
# SIZE=500MB
SIZE=1G
# Serial console or VGA default
# CONSOLE=true
# Distribution mirror
# MIRROR=http://mirror.aarnet.edu.au/debian/
#MIRROR=http://ftp.us.debian.org/debian/
MIRROR=http://mirror.internode.on.net/pub/debian/
# Distribution version
# DIST_VERSION=testing
DIST_VERSION=jessie
# Kernel version
# KERNEL_VERSION='4.3.0-1-amd64'
KERNEL_VERSION='3.16.0-4-amd64'

    

# TODO Need to generalize across hardware...
INTERFACE=enp3s0
# Install minimal python, used for ansible provisioning etc
# PYTHON=true

# TODO

# - output filename
# - change mnt working dir name to tmp
# - control debootstrap local cache with a flag...
# - caching will break if interupted - so place a flag/marker file if succeeded
# - be good to install generic kernel then extract kernel version automatically using uname or lsb_release...
# - support for multiple kernels at boot?
# - check if syslinux can automatically find kernel image and ram image without having to 
# set as parameters
# - use chroot for all fs modifications instead of modifying directly from host?



############################

# cache bootstrap files locally
[ ! -d $DIST_VERSION ] && debootstrap $DIST_VERSION $DIST_VERSION/ $MIRROR

# create image
rm fs.img
dd if=/dev/zero of=fs.img bs=$SIZE count=1 || exit

fdisk fs.img << EOF
n
p
1
2048

a
p
w
EOF

# loop devices
losetup -f fs.img /dev/loop0 || exit
losetup -f fs.img -o $((2048 * 512)) /dev/loop1 || exit

# make filesystem, mount and copy files
mkfs.ext4 /dev/loop1 || exit

# grab filesystem uuid
UUID=$( blkid -p -s UUID /dev/loop1 | sed 's/.*="\([^"]*\).*/\1/' )


rm -rf mnt && mkdir mnt || exit
mount /dev/loop1 mnt || exit

cp -rp $DIST_VERSION/* mnt || exit


# TODO VERY IMPORTANT - in old version, check if need to specify kernel at all as arg...

# create chroot environment
pushd mnt || exit
for i in /proc /sys /dev; do mount -B $i .$i; done || exit

# install kernel and boot mbr
chroot . <<- EOF
apt-get -y install linux-image-$KERNEL_VERSION
apt-get -y install syslinux
apt-get -y install extlinux
mkdir -p /boot/syslinux
extlinux --install /boot/syslinux
dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/loop0
EOF

#
## set root passwd
#if [ -n "$ROOTPASSWD" ]; then
#chroot . <<- EOF
#echo root:$ROOTPASSWD | chpasswd
#EOF
#fi
#
## ssh keys and root login
#if [ -n "$SSHKEYS" ]; then
#chroot . <<- EOF
#apt-get -y install ssh
#mkdir /root/.ssh
#echo $SSHKEYS > /root/.ssh/authorized_keys
#chmod 400 /root/.ssh/authorized_keys
#sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
#EOF
#fi
#
## install python
#if [ -n "$PYTHON" ]; then
#chroot . <<- EOF
#apt-get -y install python2.7
#ln -s /usr/bin/python2.7 /usr/bin/python
#EOF
#fi

# https://lime-technology.com/wiki/index.php/Boot_Codes
# want testing 4 kernel as well....
# syslinux boot configuration
# the indenting around if/else is needed
if [ -n "$CONSOLE" ]; then
cat > ./boot/syslinux/syslinux.cfg <<- EOF
CONSOLE 0
SERIAL 0 115200 0
DEFAULT linux
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL_VERSION ../vmlinuz-$KERNEL_VERSION
  APPEND rw root=UUID=$UUID initrd=../initrd.img-$KERNEL_VERSION vga=normal fb=false console=ttyS0,115200n8
EOF
else
cat > ./boot/syslinux/syslinux.cfg <<- EOF
DEFAULT linux
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL_VERSION ../vmlinuz-$KERNEL_VERSION
  APPEND acpi=off rw root=UUID=$UUID initrd=../initrd.img-$KERNEL_VERSION
EOF
fi

# Note Deb/Ubuntu interface name change http://forums.debian.net/viewtopic.php?f=19&t=122795
# network interfaces
cat > ./etc/network/interfaces <<- EOF
auto lo
iface lo inet loopback

allow-hotplug $INTERFACE
iface $INTERFACE inet dhcp
EOF


# unmount everythiing
for i in /proc /sys /dev; do umount .$i; done
popd
umount mnt
losetup -D

rmdir mnt

chmod 666 fs.img

# also make a virtualbox image if we can
# rm fs.vdi
# which VBoxManage && VBoxManage convertfromraw --format VDI fs.img fs.vdi && chmod 666 fs.vdi

