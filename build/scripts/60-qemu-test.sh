#!/bin/sh
# 60-qemu-test.sh - boot smoke-test do ISO no QEMU (UEFI/OVMF)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"
ISO="$ROOT/out/$DISTRO_NAME-$DISTRO_VER.iso"

[ -f "$ISO" ] || { echo "ISO nao existe. Rode 50-iso.sh antes."; exit 1; }

# KVM dentro do WSL2 costuma nao existir; cai p/ TCG.
ACCEL="-accel kvm"
[ -e /dev/kvm ] || { ACCEL=""; echo ">> sem /dev/kvm: usando TCG (lento)"; }

exec qemu-system-x86_64 -M q35 -m 4096 $ACCEL \
    -cpu max \
    -bios /usr/share/OVMF/OVMF_CODE.fd \
    -drive file="$ISO",media=cdrom,readonly=on \
    -boot d -vga std -netdev user,id=n0 -device e1000,netdev=n0