
### Create a bootable linux image using only basic shell tools

Uses fdisk, losetup, debootstrap, chroot, syslinux

### Build image
```
# Edit build vars at top of file
sudo ./build.sh

# use umount.sh to clean up mounts if ./build.sh does not complete
```

### Run/boot using kvm
```
# Simple
sudo chown $USER fs.img 
kvm fs.img 

# Using bridge tap with running dhcp service
sudo kvm fs.img -net nic -net tap,ifname=mybr0
ssh 10.1.1.20
```

### Copy to a thumbdrive
```
dd if=fs.img of=/dev/sdb bs=1M
```


