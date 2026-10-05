#!/bin/sh
# 70-dualboot.sh - instalador do Winux no disco alvo (rodar do live ISO)
#
# USO:
#   70-dualboot.sh /dev/nvme0n1          # dry-run (mostra o plano)
#   70-dualboot.sh /dev/nvme0n1 --yes    # executa
#
# PRE-CONDICOES (feitas pelo usuario no Windows, com comando explicito):
#   1. D: movido para E:/F: (iCloud/Steam/etc.)
#   2. Disco alvo LIBERADO (pode ainda estar MBR com particao D: antiga)
# O Windows (disco Kingston, ESP proprio) NAO e tocado: apenas leitura
# p/ localizar o bootmgfw.efi e fazer chainload no GRUB.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"

TARGET="$1"; [ -n "$TARGET" ] || { echo "uso: $0 /dev/nvme0n1 [--yes]"; exit 1; }
YES=0; [ "$2" = "--yes" ] && YES=1

# --- guardas de seguranca ---
[ -b "$TARGET" ] || { echo "ERRO: $TARGET nao e um block device"; exit 1; }
echo "$TARGET" | grep -q '/dev/nvme' || { echo "ERRO: alvo deve ser NVMe (o disco dedicado do Winux)"; exit 1; }

# nao pode ser o disco onde o proprio sistema ao vivo esta rodando
BOOTDEV="$(lsblk -no PKNAME "$(findmnt -no SOURCE /)")"
[ "$BOOTDEV" = "$(basename "$TARGET")" ] && { echo "ERRO: alvo e o disco de boot atual"; exit 1; }

# nao pode ter particao montada
mount | grep -q "$TARGET" && { echo "ERRO: alvo tem particao montada"; exit 1; }

echo "== Plano de instalacao do Winux =="
echo "   Disco alvo:  $TARGET ($(lsblk -dno SIZE "$TARGET"))"
echo "   Particoes:   GPT | ESP 512M fat32 | root BTRFS (resto, subvol @)"
echo "   Bootloader:  GRUB no ESP do alvo | default=winux | timeout=10"
echo "   Windows:     chainload do ESP original (so leitura, intocado)"

[ "$YES" = "1" ] || { echo ">> dry-run. Rode com --yes para executar."; exit 0; }

# --- reparticiona o alvo (DESTRUTIVO, so com --yes) ---
wipefs -a "$TARGET"
parted -s "$TARGET" mklabel gpt
parted -s "$TARGET" mkpart ESP fat32 1MiB 513MiB
parted -s "$TARGET" set 1 esp on
parted -s "$TARGET" mkpart root 513MiB 100%

ESP="${TARGET}p1"; ROOT="${TARGET}p2"
mkfs.vfat -F32 -n WINUX-ESP "$ESP"
mkfs.btrfs -f -L WINUX "$ROOT"

# --- subvol @ + mount ---
mount -t btrfs "$ROOT" /mnt
btrfs subvolume create /mnt/@
umount /mnt
mount -t btrfs -o subvol=@ "$ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$ESP" /mnt/boot/efi

# --- copia o rootfs do live para o disco ---
rsync -a --numeric-ids --exclude '/proc' --exclude '/sys' --exclude '/dev' --exclude '/boot/efi' \
    /live/ /mnt/ 2>/dev/null || rsync -a --numeric-ids \
    --exclude '/proc' --exclude '/sys' --exclude '/dev' --exclude '/boot/efi' \
    /run/live/medium/live/../.. /mnt/ 2>/dev/null || true

# --- fstab por UUID ---
ROOT_UUID="$(blkid -s UUID -o value "$ROOT")"
ESP_UUID="$(blkid -s UUID -o value "$ESP")"
cat > /mnt/etc/fstab <<EOF
UUID=$ROOT_UUID  /       btrfs  subvol=@,compress=zstd:1,noatime  0 1
UUID=$ESP_UUID   /boot/efi  vfat  umask=0077                     0 1
EOF

# --- prepara chroot ---
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /dev /mnt/dev
mount --bind /run /mnt/run

# --- kernel + modulos + headers p/ DKMS + initramfs + nvidia dentro do alvo ---
cp "$ROOT/out/bzImage-$KVER" /mnt/boot/vmlinuz-$KVER
rsync -a "$ROOT/out/modules/lib/modules/" /mnt/lib/modules/
# headers completos do nosso kernel (DKMS precisa da arvore preparada)
if [ -d "$ROOT/src/linux-$KVER" ]; then
    mkdir -p /mnt/usr/src
    rsync -a --exclude '.git' "$ROOT/src/linux-$KVER/" "/mnt/usr/src/linux-headers-$KVER/"
    chroot /mnt bash -c "cd /usr/src/linux-headers-$KVER && make modules_prepare ARCH=x86_64 >/dev/null 2>&1 || true"
    ln -sfn /usr/src/linux-headers-$KVER "/mnt/lib/modules/$KVER/build"
    ln -sfn /usr/src/linux-headers-$KVER "/mnt/lib/modules/$KVER/source"
fi
chroot /mnt bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y --no-install-recommends initramfs-tools nvidia-driver nvidia-kernel-dkms efibootmgr
    dkms autoinstall || true
    KVER_IMG=$(ls /lib/modules | sort -V | tail -1)
    mkinitramfs -o /boot/initrd.img-$KVER_IMG $KVER_IMG
    echo winux > /etc/hostname
'
[ -f /mnt/boot/initrd.img-$KVER ] || { echo "ERRO: initramfs nao gerado"; exit 1; }

# --- GRUB no ESP do alvo ---
chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=WINUX --no-nvram

# --- localiza o Windows (ESP original, so leitura) para chainload ---
WIN_ESP=""
for d in /dev/sd* /dev/nvme*; do
    for p in ${d}[0-9]* ${d}p[0-9]*; do
        [ -e "$p" ] || continue
        T="$(mktemp -d)"
        if mount -r "$p" "$T" 2>/dev/null; then
            if [ -f "$T/EFI/Microsoft/Boot/bootmgfw.efi" ]; then WIN_ESP="$p"; fi
            umount "$T"
        fi
        rmdir "$T" 2>/dev/null || true
        [ -n "$WIN_ESP" ] && break
    done
    [ -n "$WIN_ESP" ] && break
done

# --- grub.cfg: default=winux, timeout=10, chainload Windows ---
cat > /mnt/boot/grub/grub.cfg <<EOF
set timeout=10
set default=0
menuentry "Winux (alto desempenho)" {
    load_video
    search --no-floppy --fs-uuid $ROOT_UUID
    linux /boot/vmlinuz-$KVER root=UUID=$ROOT_UUID rw quiet
    initrd /boot/initrd.img-$KVER
}
EOF
if [ -n "$WIN_ESP" ]; then
    WIN_UUID="$(blkid -s UUID -o value "$WIN_ESP")"
    cat >> /mnt/boot/grub/grub.cfg <<EOF
menuentry "Windows 11" {
    search --set=root --fs-uuid $WIN_UUID
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF
    echo ">> Windows localizado em $WIN_ESP (chainload)"
else
    echo ">> ATENCAO: Windows nao encontrado. Selecione via BIOS (F8)."
fi

# --- ordem de boot: Winux como padrao ---
chroot /mnt efibootmgr --create --disk "$TARGET" --part 1 --label "Winux" --loader '\EFI\winux\shimx64.efi' 2>/dev/null \
    || chroot /mnt efibootmgr --create --disk "$TARGET" --part 1 --label "Winux" --loader '\EFI\WINUX\grubx64.efi'

echo ">> instalacao concluida. Reinicie e escolha pelo menu (ou boot F8)."