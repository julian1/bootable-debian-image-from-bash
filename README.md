
### Create bootable linux images with basic shell tools

Simple example code using, fdisk, losetup, debootstrap, chroot, syslinux

#### Build image
```
# edit config vars, then
./build-debian-image.sh
```

#### boot using kvm
```
./tools/start-kvm.sh ./build/stretch-4.9.0-4-amd64.img
```

#### TODO

- integrate qcow

