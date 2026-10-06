#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p /tmp/rc
mountpoint -q /tmp/rc || mount -o subvol=@ /dev/sdg2 /tmp/rc
echo "=== linha linux do grub.cfg instalado ==="
grep 'linux /@' /tmp/rc/boot/grub/grub.cfg
echo "=== linha fstab ==="
grep btrfs /tmp/rc/etc/fstab
umount /tmp/rc