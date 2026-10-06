#!/bin/sh
# fix-esp-chain.sh - cria o grub.cfg de encadeamento na ESP.
# O core (BOOTX64.EFI) e carregado da ESP e procura o prefix embutido /boot/grub
# NELA. Como os modulos/config estao na particao ROOT (btrfs, separada), gravamos
# um grub.cfg minimo na ESP que busca a ROOT por UUID, aponta o prefix e chama o
# normal (que le o grub.cfg real da particao root).
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p /tmp/rc /tmp/v
mountpoint -q /tmp/v || mount /dev/sdg1 /tmp/v
mountpoint -q /tmp/rc || mount -o compress=zstd:1 /dev/sdg2 /tmp/rc
ROOT_UUID=$(blkid -s UUID -o value /dev/sdg2)

# grub.cfg de encadeamento na ESP (varios caminhos, por seguranca)
for D in /tmp/v/boot/grub /tmp/v/EFI/BOOT /tmp/v/EFI/WINUX; do
    mkdir -p "$D"
    cat > "$D/grub.cfg" <<EOF
search --no-floppy --fs-uuid $ROOT_UUID --set=root
set prefix=(\$root)/boot/grub
configfile \$prefix/grub.cfg
EOF
    echo "  escrito: $D/grub.cfg"
done
echo "=== ROOT_UUID=$ROOT_UUID ==="
umount /tmp/rc /tmp/v