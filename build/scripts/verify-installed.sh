#!/bin/sh
# verify-installed.sh - verifica o que foi instalado no NVMe
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "=== particoes ==="
lsblk -no NAME,SIZE,FSTYPE,LABEL /dev/sdg
echo "=== ESP (EFI) ==="
mkdir -p /tmp/v; mountpoint -q /tmp/v || mount /dev/sdg1 /tmp/v
find /tmp/v -name '*.efi' 2>/dev/null | sed 's#^/tmp/v#ESP#'
echo "=== ROOT (btrfs @) ==="
mkdir -p /tmp/r; mountpoint -q /tmp/r || mount -o subvol=@ /dev/sdg2 /tmp/r
ls -la /tmp/r/boot/vmlinuz-* /tmp/r/boot/initrd.img-* 2>/dev/null
echo "--- grub.cfg ---"
cat /tmp/r/boot/grub/grub.cfg 2>/dev/null
echo "--- fstab ---"
cat /tmp/r/etc/fstab 2>/dev/null
echo "--- hostname ---"
cat /tmp/r/etc/hostname 2>/dev/null
echo "--- modulos do kernel ---"
ls /tmp/r/lib/modules/ 2>/dev/null