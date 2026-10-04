#!/bin/sh
# 45-bootfiles.sh - kernel + initrd no /boot do rootfs (para live/instalacao)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"
RFS="$ROOT/out/rootfs"

# instala os modulos do nosso kernel no rootfs (necessario p/ DKMS/NVIDIA)
mkdir -p "$RFS/lib/modules"
rsync -a "$ROOT/out/modules/lib/modules/" "$RFS/lib/modules/"
# headers p/ DKMS
mkdir -p "$RFS/usr/src"
if [ -d "$ROOT/out/headers/include" ]; then
    rsync -a "$ROOT/out/headers/" "$RFS/usr/src/linux-headers-$KVER/"
    echo ">> headers em /usr/src/linux-headers-$KVER"
fi

cp "$ROOT/out/bzImage-$KVER" "$RFS/boot/vmlinuz-$KVER"

echo ">> bootfiles ok"