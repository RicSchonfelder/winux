#!/bin/sh
# teste local do fluxo de particionamento/mount do instalador (WSL, loop device)
set -x
T=/dev/loop0
IMG=/root/test.img
[ -b "$T" ] || { losetup /dev/loop0 "$IMG"; }
wipefs -a "$T" 2>/dev/null || true
sfdisk "$T" <<'SFDISK' || true
label: gpt
start=1MiB, size=512MiB, type=U
type=L
SFDISK
partprobe "$T" 2>/dev/null || true
sleep 1
ESP="${T}p1"; R="${T}p2"
echo "ESP=$ESP R=$R"
ls -la "$ESP" "$R" 2>&1
mkfs.vfat -F32 -n TEST "$ESP"
echo MKFS_VFAT_DONE
mkfs.btrfs -f -L TESTB "$R"
echo MKFS_BTRFS_DONE
umount /mnt 2>/dev/null || true
mkdir -p /mnt
mount -t btrfs "$R" /mnt
echo MOUNT_OK
btrfs subvolume create /mnt/@
echo SUBVOL_OK
umount /mnt
mount -t btrfs -o subvol=@,compress=zstd:1,noatime "$R" /mnt
echo MOUNT_SUBVOL_OK
mkdir -p /mnt/boot/efi
mount "$ESP" /mnt/boot/efi
echo MOUNT_ESP_OK
# testa rsync de um diretório pequeno
mkdir -p /mnt/usr/bin && echo hello > /mnt/usr/bin/testfile
echo RSYNC_WRITE_OK
umount /mnt/boot/efi 2>/dev/null || true
umount /mnt
echo ALL_DONE
losetup -d "$T" 2>/dev/null || true
rm -f "$IMG"