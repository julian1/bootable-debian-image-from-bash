
#### Creates a bootable linux image using only basic shell tools

Uses fdisk, losetup, debootstrap, chroot, syslinux

#### Build image
```
# edit script vars, then
sudo ./build.sh 2>&1 | tee log.txt
```

#### Boot with kvm redirecting serial output
```
sudo ./start.sh ./resources/fs.img
```

#### Reset kvm bridge tap
```
sudo /etc/qemu-ifdown mybr0
```

#### Image thumbdrive
```
# if thumb is /dev/sdb
sudo dd if=fs.img of=/dev/sdb bs=1M
```

#### TODO
```
try zfs - on initrd - non encrypted
figure out bridge tap without root permissions

```
