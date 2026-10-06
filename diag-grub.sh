#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p /tmp/rc
mountpoint -q /tmp/rc || mount -o compress=zstd:1 /dev/sdg2 /tmp/rc
echo "=== /boot/grub ==="; ls /tmp/rc/boot/grub/ 2>&1
echo "=== modulos x86_64-efi (contagem) ==="; ls /tmp/rc/boot/grub/x86_64-efi/ 2>/dev/null | wc -l
echo "=== normal.mod existe? ==="; ls -la /tmp/rc/boot/grub/x86_64-efi/normal.mod 2>&1
echo "=== prefix embutido no core (strings) ==="; strings /tmp/rc/boot/efi/EFI/WINUX/grubx64.efi 2>/dev/null | grep -iE "boot/grub|prefix|hd0|gpt|/@" | head
echo "=== sbin/init ==="; ls -la /tmp/rc/sbin/init 2>&1
umount /tmp/rc