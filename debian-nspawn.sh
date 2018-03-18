#!/bin/bash


############################
# Configuration!

KEYS="$(cat /home/meteo/.ssh/authorized_keys)"
# DANGEROUS - edit me!
ROOTPASSWD=root
MIRROR=http://ftp.us.debian.org/debian/

# stretch 
DIST=stretch
PYTHON=yes


############################

# check privs
if [[ "$EUID" -ne 0 ]]; then
   # also correct debootstrap permissions.
   echo "Must run as root for mount/losetup" 
   exit 1
fi

if [ -z "$KEYS" ]; then
  echo "Need ssh keys!"
  exit 1
fi

if [ "$ROOTPASSWD" = "root" ]; then
  echo "WARNING change the root password!"
fi


############################

set -x


cache="./build/$DIST-cache"
target="./build/$DIST.chroot"

# maybe delete stale cache. eg. 1 day.
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
[ ! -d "$cache" ] && debootstrap "$DIST" "$cache/" $MIRROR


############################
# build filesystems

rm -rf "$target"

# copy debootstrap files across to mnt
cp -rp "$cache" $target || exit


############################
# install kernel, and configure


# install config, ssh
chroot --userspec=0:0 $target <<- EOF

cat > /etc/network/interfaces << EOF2
auto lo
iface lo inet loopback

# container nic
# setting hwaddress here works with nspawn
auto host0
iface host0 inet dhcp
hwaddress ether 02:01:02:03:04:08
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


