
### Create a bootable linux image using only basic shell tools

Uses fdisk, losetup, debootstrap, chroot, syslinux

### build an image
```
sudo ./build.sh
```

### example to burn to a thumbdrive
```
dd if=fs.img of=/dev/sdb bs=1M
```


