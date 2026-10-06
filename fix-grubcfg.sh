#!/bin/sh
# fix-grubcfg.sh - corrige o grub.cfg instalado para usar o subvolume @ do btrfs
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KVER=6.18.54
mkdir -p /tmp/r
mountpoint -q /tmp/r || mount -o subvol=@ /dev/sdg2 /tmp/r
ROOT_UUID=$(blkid -s UUID -o value /dev/sdg2)
cat > /tmp/r/boot/grub/grub.cfg <<EOF
set timeout=10
set default=0
menuentry "Winux (alto desempenho)" {
    search --no-floppy --fs-uuid $ROOT_UUID --set=root
    linux /@/boot/vmlinuz-$KVER root=UUID=$ROOT_UUID rootflags=subvol=@ rootfstype=btrfs rw console=tty0 console=ttyS0
    initrd /@/boot/initrd.img-$KVER
}
menuentry "Windows 11" {
    insmod part_gpt
    insmod fat
    search --no-floppy --file /EFI/Microsoft/Boot/bootmgfw.efi --set=root
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF
echo "=== grub.cfg corrigido (ROOT_UUID=$ROOT_UUID) ==="
cat /tmp/r/boot/grub/grub.cfg
umount /tmp/r