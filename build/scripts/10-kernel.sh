#!/bin/sh
# 10-kernel.sh - baixa, configura (desktop Haswell) e compila o kernel
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"

SRC="$ROOT/src"; OUT="$ROOT/out"; KDIR="$SRC/linux-$KVER"
FRAG="$ROOT/build/config/haswell-desktop.fragment"
JOBS="$(nproc)"

mkdir -p "$SRC" "$OUT"

# --- baixa ---
if [ ! -d "$KDIR" ]; then
    cd "$SRC"
    MAJ="$(echo "$KVER" | cut -d. -f1).x"
    curl -# -L -o "linux-$KVER.tar.xz" \
        "https://cdn.kernel.org/pub/linux/kernel/v${MAJ}/linux-$KVER.tar.xz"
    tar -xf "linux-$KVER.tar.xz"
fi

cd "$KDIR"
# --- configura: defconfig (base sanada p/ desktop) + fragmento delta + resolve deps ---
# tinyconfig nao serve: Debian/systemd/XFCE exigem PRINTK, SYSFS, PROC_FS,
# BINFMT_ELF, CGROUPS, OVERLAY_FS, SQUASHFS etc.
GENCFG="$ROOT/build/config/.config.generated"
if [ ! -f .config ] || [ ! -f "$GENCFG" ] || [ "$FRAG" -nt "$GENCFG" ]; then
    make ARCH=x86_64 defconfig >/dev/null
    scripts/kconfig/merge_config.sh -m .config "$FRAG" >/dev/null
    make ARCH=x86_64 olddefconfig >/dev/null
    cp .config "$GENCFG"
fi

# --- compila (march=haswell via KCFLAGS) ---
make ARCH=x86_64 -j"$JOBS" KCFLAGS="$KCFLAGS" bzImage
make ARCH=x86_64 -j"$JOBS" KCFLAGS="$KCFLAGS" modules
make ARCH=x86_64 KCFLAGS="$KCFLAGS" INSTALL_MOD_PATH="$OUT/modules" modules_install
make ARCH=x86_64 INSTALL_HDR_PATH="$OUT/headers" headers_install

cp arch/x86/boot/bzImage "$OUT/bzImage-$KVER"
cp System.map "$OUT/System.map-$KVER"
echo ">> kernel: $OUT/bzImage-$KVER ($(du -h "$OUT/bzImage-$KVER" | cut -f1))"