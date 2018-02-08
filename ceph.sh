#!/bin/bash

apt install -y parted xfsprogs

foo_device=$(losetup -f)
fallocate -l 40G /tmp/sdc
losetup $foo_device /tmp/sdc
parted $foo_device -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_FOO 1 -1

foo_device_J=$(losetup -f)
fallocate -l 40G /tmp/sdd
losetup $foo_device_J /tmp/sdd
parted $foo_device_J -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_FOO_J 1 -1
