#!/bin/sh
# 45-bootfiles.sh - kernel + initrd no /boot do rootfs (para live/instalacao)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"
RFS="$ROOT/out/rootfs"

# instala os modulos do nosso kernel no rootfs (necessario p/ DKMS/NVIDIA)
mkdir -p "$RFS/lib/modules"
rsync -a "$ROOT/out/modules/lib/modules/" "$RFS/lib/modules/"
# NOTA: headers completos p/ DKMS sao preparados na instalacao
# (70-dualboot.sh), nao no ISO — evita inchar a midia.

cp "$ROOT/out/bzImage-$KVER" "$RFS/boot/vmlinuz-$KVER"

echo ">> bootfiles ok"