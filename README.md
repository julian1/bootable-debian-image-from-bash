
### Creates a bootable linux image using only basic shell tools

Uses fdisk, losetup, debootstrap, chroot, syslinux

#### Build image
```
# edit script vars, then
sudo ./build.sh 2>&1 | tee log.txt
```

#### Mount and do a change root to search
```
sudo ./mount.sh
sudo chroot resources/mnt/

# look for appropriate kernel to install
apt-get -y install aptitude
aptitude search linux-image
```

#### Boot image with kvm and redirect console to stdout
```
kvm ./resources/precise-3.2.0-23-virtual.img -nographic

# login root,root
/sbin/shutdown -h now
```

#### Reset kvm bridge tap
```
sudo /etc/qemu-ifdown mybr0
```

#### Create rescue thumbdrive
```
# if thumbdrive is /dev/sdb,
sudo dd if=fs.img of=/dev/sdb bs=1M
```

#### TODO
```
try zfs - on initrd - non encrypted
figure out bridge tap without root permissions
```
