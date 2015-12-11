#!/bin/bash -x

# edit me!
SSHKEY="$(cat /home/meteo/.ssh/id_rsa.pub)"
ROOTPASSWD=root
FSSIZE=1G

rm fs.img fs.vdi

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

mkfs.ext4 /dev/loop1 || exit

[ -d mnt ] || mkdir mnt
mount /dev/loop1 mnt || exit
ls mnt

[ ! -d jessie ] && debootstrap jessie mnt/ http://mirror.aarnet.edu.au/debian/

cp -rp jessie/* mnt || exit

cd mnt
for i in /proc /sys /dev; do mount -B $i .$i; done || exit

chroot . <<- EOF
apt-get -y install linux-image-3.16.0-4-amd64
apt-get -y install syslinux
apt-get -y install extlinux
apt-get -y install ssh
apt-get -y install python2.7
ln -s /usr/bin/python2.7 /usr/bin/python
mkdir -p /boot/syslinux
extlinux --install /boot/syslinux
dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/loop0
echo root:$ROOTPASSWD | chpasswd
mkdir /root/.ssh
echo $SSHKEY > /root/.ssh/authorized_keys
chmod 400 /root/.ssh/authorized_keys
EOF

# get fs uuid
UUID=$( blkid -p -s UUID  /dev/loop1 | sed 's/.*="\([^"]*\).*/\1/' )

# boot with vga output
#cat > ./boot/syslinux/syslinux.cfg <<- EOF
#DEFAULT linux
#LABEL linux
#  SAY Now booting the kernel from SYSLINUX...
#  KERNEL ../vmlinuz-3.16.0-4-amd64
#  APPEND rw root=UUID=$UUID initrd=../initrd.img-3.16.0-4-amd64
#EOF

# boot using console tty output
cat > ./boot/syslinux/syslinux.cfg <<- EOF
CONSOLE 0
SERIAL 0 115200 0

DEFAULT linux
LABEL linux
  SAY Now booting the kernel from SYSLINUX...
  KERNEL ../vmlinuz-3.16.0-4-amd64
  APPEND rw root=UUID=$UUID initrd=../initrd.img-3.16.0-4-amd64 vga=normal fb=false console=ttyS0,115200n8
EOF

cat > ./etc/network/interfaces << EOF
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
  address 172.16.210.254
  netmask 255.255.255.0
EOF

sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' ./etc/ssh/sshd_config

for i in /proc /sys /dev; do umount .$i; done
cd ..

umount mnt

losetup -D

# also make a virtualbox image if we can
which VBoxManage && VBoxManage convertfromraw --format VDI fs.img fs.vdi && chmod 666 fs.vdi


