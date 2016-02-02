
### Create a bootable linux image using only basic shell tools

Uses fdisk, losetup, debootstrap, chroot, syslinux

### Build image
```
# Edit config vars, then
sudo ./build.sh
# or with log
sudo ./build.sh 2>&1 | tee log.txt

# Use umount.sh to clean up loop mounts if ./build.sh fails
```

### Boot with kvm
```
kvm fs.img 
```

### Boot with kvm and attach and redirect serial output 
```
kvm fs.img -nographic

# (login and shutdown to restore shell)
```

### Boot with kvm with bridge tap with running dhcp service etc
```
sudo kvm fs.img -nographic -net nic -net tap,ifname=mybr0

# can now ssh root@10.1.1.20
```


### Postinstall

Edit, dhcp interface in /etc/network/interfaces if kernel uses
non-predictable udev assignment


### Image thumbdrive
```
# if thumb is /dev/sdb
sudo dd if=fs.img of=/dev/sdb bs=1M
```

#### TODO
```
zfs - on initrd - non encrypted

```
