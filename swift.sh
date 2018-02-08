#!/bin/bash

apt install -y parted xfsprogs

free_device=$(losetup -f)
fallocate -l 1G /tmp/sdc
losetup $free_device /tmp/sdc
parted $free_device -s -- mklabel gpt mkpart KOLLA_SWIFT_DATA 1 -1
sudo mkfs.xfs -f -L d0 ${free_device}p1
