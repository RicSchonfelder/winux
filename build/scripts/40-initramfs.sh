#!/bin/sh
# 40-initramfs.sh - initramfs do rootfs via initramfs-tools (Debian)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"
RFS="$ROOT/out/rootfs"

chroot "$RFS" bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y --no-install-recommends initramfs-tools
    KVER_IMG=$(ls /lib/modules | sort -V | tail -1)
    mkinitramfs -o /boot/initrd.img-$KVER_IMG $KVER_IMG
    echo ">> initramfs: $KVER_IMG"
'