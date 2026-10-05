#!/bin/sh
# 00-deps.sh - toolchain de build (roda no WSL / maquina de build)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

apt-get update
apt-get install -y \
    build-essential bc bison flex libssl-dev libncurses-dev libelf-dev \
    cpio xz-utils zstd \
    debootstrap rsync \
    xorriso grub-pc-bin grub-efi-amd64-bin \
    dosfstools mtools parted btrfs-progs \
    squashfs-tools \
    qemu-system-x86 ovmf \
    git curl wget ca-certificates

echo ">> deps ok"