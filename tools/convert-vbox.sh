#!/bin/bash
# create a virtual box image 
# taken from old code -need to review

if [ -z "$1" ]; then
   echo "usage $0 <path to image>" 
   exit 1
fi


image="$1"

VBoxManage convertfromraw --format VDI $image fs.vdi 

chmod 666 fs.vdi


