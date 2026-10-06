#!/bin/sh
# fix-mountpoints.sh - cria os pontos de montagem que faltam no subvolume @.
# Sem /dev, /run, /proc, /sys o switch_root do initramfs falha e o sistema
# cai no BusyBox ("No init found").
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p /tmp/r
mountpoint -q /tmp/r || mount -o subvol=@ /dev/sdg2 /tmp/r
echo "criando pontos de montagem no subvolume @..."
for d in dev run proc sys tmp boot/efi; do
    mkdir -p "/tmp/r/$d"
    echo "  / $d  -> $(ls -ld "/tmp/r/$d" 2>/dev/null | awk '{print $1}')"
done
# garante que /sbin/init existe (systemd)
echo "=== checando /sbin/init no subvolume ==="
ls -la /tmp/r/usr/sbin/init /tmp/r/sbin/init 2>&1 | head
echo "=== fstab ==="
cat /tmp/r/etc/fstab
umount /tmp/r