#!/bin/bash

exit fixme!
exit

base=$( dirname $0)

# exit

"$base/mount.sh $1" || exit

chroot ./build/mnt

# put in a trap
"$base/umount.sh"

