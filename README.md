
### TODO

- check if syslinux can automatically find kernel image and ram image without having to 
set as parameters
- use chroot for all fs modifications instead of modifying directly from host?

### Create a bootable linux image using only basic shell tools

Uses fdisk, losetup, debootstrap, chroot, syslinux

### Build image
```
# Edit config vars, then
sudo ./build.sh

# Use umount.sh to clean up loop mounts if ./build.sh fails
```

### Boot image using kvm
```
kvm fs.img 

# Using bridge tap with running dhcp service etc
sudo kvm fs.img -net nic -net tap,ifname=mybr0
ssh 10.1.1.20
```

### Copy to a thumbdrive
```
# if thumb is /dev/sdb
sudo dd if=fs.img of=/dev/sdb bs=1M
```


