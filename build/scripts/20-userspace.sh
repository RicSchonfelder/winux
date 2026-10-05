#!/bin/sh
# 20-userspace.sh - debootstrap Debian (base desktop) no rootfs
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"

OUT="$ROOT/out"; RFS="$OUT/rootfs"
mkdir -p "$OUT"

# --- base ---
if [ ! -x "$RFS/usr/bin/apt" ]; then
    debootstrap --arch=amd64 --variant=minbase \
        --include=systemd,udev,kmod,dbus,iproute2,iputils-ping,ifupdown,isc-dhcp-client,procps,locales,console-setup,keyboard-configuration \
        "$DEBIAN_SUITE" "$RFS" "$DEBIAN_MIRROR"
fi

# --- sources.list (escrito do host, sem problema de quoting no chroot) ---
cat > "$RFS/etc/apt/sources.list" <<EOF
deb $DEBIAN_MIRROR $DEBIAN_SUITE main contrib non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_SUITE-updates main contrib non-free-firmware
deb ${DEBIAN_MIRROR}-security $DEBIAN_SUITE-security main contrib non-free-firmware
EOF

# --- desktop + ferramentas ---
chroot "$RFS" bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends \
        xserver-xorg xinit lightdm \
        xfce4 xfce4-goodies xfce4-terminal \
        network-manager sudo bash-completion vim nano curl wget ca-certificates git \
        pulseaudio pavucontrol \
        file-roller ristretto thunar-archive-plugin \
        firmware-linux firmware-realtek \
        live-boot live-config \
        rsync parted fdisk dosfstools btrfs-progs efibootmgr grub-efi-amd64-bin grub2-common \
        build-essential dkms
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    update-locale LANG=en_US.UTF-8
'

# --- usuario desktop ---
if ! chroot "$RFS" id "$DESKTOP_USER" >/dev/null 2>&1; then
    chroot "$RFS" useradd -m -s /bin/bash -G sudo,audio,video,input "$DESKTOP_USER"
    echo "$DESKTOP_USER:$DESKTOP_USER" | chroot "$RFS" chpasswd
    echo "$DESKTOP_USER ALL=(ALL) NOPASSWD:ALL" > "$RFS/etc/sudoers.d/winux"
fi

echo ">> userspace ok"