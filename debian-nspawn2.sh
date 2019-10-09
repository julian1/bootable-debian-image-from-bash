#!/bin/bash

############################
# Configuration!

MIRROR=http://ftp.us.debian.org/debian/
# stretch 
DIST=buster


############################

# check privs
if [[ "$EUID" -ne 0 ]]; then
   # also, require root for correct debootstrap dir permissions, during copy.
   echo "Must be root for mount privs" 
   exit 1
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
[ -d "$cache" ] || debootstrap "$DIST" "$cache/" $MIRROR

############################
# build filesystems

rm -rf "$target" || true

# copy debootstrap files across to mnt
cp -rp "$cache" $target

############################
# install kernel, and configure


# this will give us ssh root login. expect root ssh pubkeys to be injected. can then do python minimal-install, and then run ansible...

chroot --userspec=0:0 $target <<- EOF

# fail fast
set -e

apt-get -y install ssh
mkdir /root/.ssh
sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

EOF

