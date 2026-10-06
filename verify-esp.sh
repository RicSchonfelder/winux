#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p /tmp/v
mountpoint -q /tmp/v || mount /dev/sdg1 /tmp/v
echo "=== conteudo da ESP ==="
find /tmp/v -type f 2>/dev/null | sed 's#^/tmp/v#ESP#'
echo "=== tamanhos dos bootloaders ==="
ls -la /tmp/v/EFI/BOOT/BOOTX64.EFI /tmp/v/EFI/WINUX/grubx64.efi 2>&1
echo "=== grub.cfg no root ==="
mkdir -p /tmp/r
mountpoint -q /tmp/r || mount -o subvol=@ /dev/sdg2 /tmp/r
sed -n '1,3p' /tmp/r/boot/grub/grub.cfg 2>&1