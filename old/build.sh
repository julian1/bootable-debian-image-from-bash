#!/bin/bash -x

# Editable configuration!
SSHKEY="$(cat /home/$USER/.ssh/id_rsa.pub)"
ROOTPASSWD=root
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

rm -rf mnt && mkdir mnt || exit
mount /dev/loop1 mnt || exit

cp -rp jessie/* mnt || exit

# mount systems and chroot
pushd mnt
for i in /proc /sys /dev; do mount -B $i .$i; done || exit

VERSION=3.16.0-4-amd64

# install kernel, boot config, ssh
chroot . <<- EOF
apt-get -y install linux-image-$VERSION
apt-get -y install syslinux
apt-get -y install extlinux
mkdir -p /boot/syslinux
extlinux --install /boot/syslinux
dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/loop0

cat > /boot/syslinux/syslinux.cfg <<- EOF2
DEFAULT linux
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL /boot/vmlinuz-$VERSION
  APPEND rw root=UUID=$UUID initrd=/boot/initrd.img-$VERSION
EOF2

cat > /etc/network/interfaces << EOF2
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
EOF2

[ $ROOTPASSWD ] && echo root:$ROOTPASSWD | chpasswd

apt-get -y install ssh
mkdir /root/.ssh
echo $SSHKEY > /root/.ssh/authorized_keys
chmod 400 /root/.ssh/authorized_keys
sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
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

