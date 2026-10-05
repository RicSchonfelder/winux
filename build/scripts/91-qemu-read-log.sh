#!/bin/sh
# 91-qemu-read-log.sh - le o log da instalacao gravado no ESP do disco virtual
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TGT="$ROOT/out/test-target.qcow2"
[ -f "$TGT" ] || { echo "sem disco de teste"; exit 1; }

modprobe nbd 2>/dev/null || true
qemu-nbd --disconnect /dev/nbd0 2>/dev/null || true
qemu-img info "$TGT" >/dev/null
# conecta somente a particao 1 (ESP): -P1 -> /dev/nbd0p1
qemu-nbd -c /dev/nbd0 "$TGT" >/dev/null 2>&1 || { echo "falha ao conectar nbd"; exit 1; }
sleep 1

MNT=/mnt/esp-read
mkdir -p "$MNT"
if mount /dev/nbd0p1 "$MNT" 2>/dev/null; then
    echo "=== log da instalacao (ESP) ==="
    cat "$MNT/win-install.log" 2>/dev/null || echo "(sem win-install.log)"
    umount "$MNT"
else
    echo "nao montou /dev/nbd0p1; partitions:"; lsblk /dev/nbd0 2>&1 || true
fi
rmdir "$MNT" 2>/dev/null || true
qemu-nbd --disconnect /dev/nbd0 2>/dev/null || true