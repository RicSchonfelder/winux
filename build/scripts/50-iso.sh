#!/bin/sh
# 50-iso.sh - ISO bootavel (UEFI) via grub-mkrescue + live-boot (squashfs)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"

RFS="$ROOT/out/rootfs"
ISO="$ROOT/iso"; OUT="$ROOT/out"
rm -rf "$ISO"; mkdir -p "$ISO/live" "$ISO/boot/grub"

# sistema comprimido (live)
mksquashfs "$RFS" "$ISO/live/filesystem.squashfs" -comp xz -noappend

# kernel + initrd
cp "$RFS/boot/vmlinuz-$KVER" "$ISO/live/vmlinuz-$KVER"
INITRD="$RFS/boot/initrd.img-$KVER"
[ -f "$INITRD" ] || INITRD="$(ls "$RFS"/boot/initrd.img-* 2>/dev/null | head -1)"
cp "$INITRD" "$ISO/live/initrd.img"

# grub.cfg (serial + vga: permite smoke-test headless no QEMU)
cat > "$ISO/boot/grub/grub.cfg" <<EOF
set timeout=10
set default=0
serial --unit=0 --speed=115200
terminal_input serial console
terminal_output serial console
menuentry "Winux Live ($KVER)" {
    linux /live/vmlinuz-$KVER boot=live quiet console=ttyS0
    initrd /live/initrd.img
}
EOF

mkdir -p "$OUT"
grub-mkrescue -o "$OUT/$DISTRO_NAME-$DISTRO_VER.iso" "$ISO"
echo ">> ISO: $OUT/$DISTRO_NAME-$DISTRO_VER.iso"