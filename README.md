
### Create a bootable linux image using only basic shell tools

Uses fdisk, losetup, debootstrap, chroot, syslinux

### Build image
```
# Edit build vars at top of file
sudo ./build.sh
```

### Run/boot using kvm
```
sudo chown $USER fs.img 
kvm fs.img 

# or with bridge tap and running dhcp etc.
sudo kvm fs.img  -net nic -net tap,ifname=mybr0
```

### Copy to a thumbdrive
```
dd if=fs.img of=/dev/sdb bs=1M
```


