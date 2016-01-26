#!/bin/bash -x

# Configuration!
SSHKEY="$(cat ~/.ssh/authorized_keys)"
ROOTPASSWD=root
FSSIZE=1G
# CONSOLE=false
MIRROR=http://mirror.internode.on.net/pub/debian/
#DIST=jessie
#KERNEL=3.16.0-4-amd64
DIST=testing
KERNEL=4.3.0-1-amd64
PYTHON=no

############################

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

# install kernel, boot config, ssh
chroot . <<- EOF
apt-get -y install linux-image-$KERNEL
apt-get -y install syslinux
apt-get -y install extlinux
mkdir -p /boot/syslinux
extlinux --install /boot/syslinux
dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/loop0

cat > /boot/syslinux/syslinux.cfg <<- EOF2
CONSOLE 0
SERIAL 0 115200 0
DEFAULT linux
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL /boot/vmlinuz-$KERNEL
  APPEND rw root=UUID=$UUID initrd=/boot/initrd.img-$KERNEL vga=normal fb=false console=ttyS0,115200n8
EOF2

cat > /etc/network/interfaces << EOF2
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
EOF2

if [ -n "$ROOTPASSWD" ]; then 
  echo root:$ROOTPASSWD | chpasswd
fi

if [ -n "$SSHKEY" ]; then
  apt-get -y install ssh
  mkdir /root/.ssh
  echo "$SSHKEY" > /root/.ssh/authorized_keys
  chmod 400 /root/.ssh/authorized_keys
  sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
fi

if [ $PYTHON = "yes" ]; then 
  apt-get -y install python2.7
  ln -s /usr/bin/python2.7 /usr/bin/python
fi
EOF

# unmount everything
for i in /proc /sys /dev; do umount .$i; done
popd
umount mnt
losetup -D
rmdir mnt

chmod 666 fs.img

# make a virtualbox image if we can
# rm fs.vdi
# which VBoxManage && VBoxManage convertfromraw --format VDI fs.img fs.vdi && chmod 666 fs.vdi

